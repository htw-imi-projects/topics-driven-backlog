require 'net-ldap'

class AuthenticateUser
  include DomainDefinition

  def initialize(email, password)
    @email = email
    @password = password
  end

  # Service entry point
  def call
    user = get_user(@email, @password)
    expires_at = 24.hours.from_now
    {
        auth_token: {
            token: JsonWebToken.encode(user_id: user.id, exp: expires_at),
            ttl: expires_at.to_i
        },
        user: user
    }
  end

  private

  # verify user credentials
  def get_user(email, password)
    if email.present? && password.present?
      ldap_user_role = get_user_role_via_ldap(username(email), password)
      user = User.find_by(email: email)

      if user.nil?
        user = User.create!(email: email, role: ldap_user_role)
      elsif user.role != ldap_user_role
        user.update_attribute(:role, ldap_user_role)
      end

      return user if user
    end

    raise(ExceptionHandler::AuthenticationError, Message.invalid_credentials)
  end

  def get_user_role_via_ldap(username, password)
    query_result = []
    begin
      Net::LDAP.open(
          host: DomainDefinition::LDAP_HOST,
          port: DomainDefinition::LDAP_PORT,
          encryption:
              {
                  method: :simple_tls,
                  verify_mode: OpenSSL::SSL::VERIFY_NONE
              },
          base: DomainDefinition::LDAP_CONNECTSTRING,
          auth: {
              method: :simple,
              username: username,
              password: password
          }
      ) do |ldap|
        query_result = ldap.search(
            :base => DomainDefinition::LDAP_CONNECTSTRING,
            :filter => Net::LDAP::Filter.eq( 'CN', username )
        )
      end

      get_user_role(query_result)
    rescue
      raise(ExceptionHandler::AuthenticationServerIsDown, Message.contact_the_admin)
    end
  end

  def get_user_role(query_result)
    if query_result.size === 1
      user_groups = query_result[0]['memberof'].split(',')

      if user_groups.include?('DN=' . DomainDefinition::USER_GROUP_INSTRUCTOR)
        return User.roles[:instructor]
      end

      if user_groups.include?('DN=' . DomainDefinition::USER_GROUP_STUDENT)
        return User.roles[:student]
      end
    end

    raise(ExceptionHandler::AuthenticationError, Message.invalid_credentials)
  end

  def username(email)
    m = /\A(.*)@.*htw-berlin.de\z/.match(email)
    return m[1] if m
    raise(ExceptionHandler::AuthenticationError, Message.not_domain_email_address(email))
  end
end
