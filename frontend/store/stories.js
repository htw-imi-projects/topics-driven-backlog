import Vue from 'vue';

export const state = {
    initialised: false,
    data: [],
};

export const mutations = {
    /**
     * Set one or all stories
     * @param {object} state
     * @param {object} payload
     */
    set: (state, payload) => {
        if (payload.stories) {
            Vue.set(state, 'data', payload.stories);
        }

        if (payload.story) {
            const isPresent = state.data.find(
                story => story.id === payload.story.id
            );

            if (isPresent) {
                Vue.set(
                    state,
                    'data',
                    state.data.map(
                        story =>
                            story.id === payload.story.id
                                ? payload.story
                                : story
                    )
                );
            } else {
                state.data.push(payload.story);
            }
        }
    },

    /**
     * Remove story from data set
     * @param {object} state
     * @param {object} payload
     */
    remove: (state, payload) => {
        Vue.set(
            state,
            'data',
            state.data.filter(story => story.id !== payload.id)
        );
    },
};

export const actions = {
    /**
     * Initialises the stories store
     * @param {object} state
     * @param {function} dispatch
     * @returns {Promise}
     */
    init({ state, dispatch }) {
        return new Promise((resolve, reject) => {
            if (!state.initialised) {
                dispatch('fetch').then(() => {
                    state.initialised = true;
                    resolve();
                }, reject);
            } else {
                resolve();
            }
        });
    },

    /**
     * Fetches all stories from the API and updates store
     * @param {function} commit
     * @returns {Promise}
     */
    fetch({ commit }) {
        return new Promise((resolve, reject) => {
            Vue.http.get('/stories').then(response => {
                commit('set', {
                    stories: response.body,
                });

                resolve(response.body);
            }, reject);
        });
    },

    /**
     * Saves a story to the API and updates store
     * @param {function} commit
     * @param {object} payload (story)
     * @returns {Promise}
     */
    save({ commit }, payload) {
        return new Promise((resolve, reject) => {
            Vue.http.post(`/projects/${payload.project_id}/stories`, payload.story).then(response => {
                commit('set', {
                    story: response.body,
                });

                resolve(response.body);
            }, reject);
        });
    },

    /**
     * Patches a given field of a given story with a given value or all given values
     * @param {function} commit
     * @param {object} payload (id, field, value, values)
     * @returns {Promise}
     */
    patch({ commit, dispatch }, payload) {
        return new Promise((resolve, reject) => {
            let values = {};

            if (payload.values) {
                values = payload.values;
            } else {
                values[payload.field] = payload.value;
            }

            Vue.http
                .patch(`/stories/${payload.id}`, values)
                .then(response => {
                    if (payload.fetch) {
                        dispatch('fetch').then(resolve, reject);
                    } else {
                        commit('set', {
                            story: response.body,
                        });

                        resolve(response.body);
                    }
                }, reject);
        });
    },

    /**
     * Deletes a given story
     * @param {function} commit
     * @param {object} payload (id)
     * @returns {Promise}
     */
    delete({ commit }, payload) {
        return new Promise((resolve, reject) => {
            Vue.http.delete(`/stories/${payload.id}`).then(() => {
                commit('remove', payload);

                resolve();
            }, reject);
        });
    },
};

export const getters = {
    /**
     * All stories
     * @param {object} state
     * @returns {array}
     */
    all: state => (state.initialised ? state.data : []),

    byProject: (state, getters, rootState, rootGetters) => (id) => {
        return rootGetters['projects/byId'](id).stories || [];
    },

    /**
     * Find a story by identifier
     * @param {object} state
     * @returns {(object|null)}
     */
    byIdentifier: state => value =>
        state.initialised
            ? state.data.find(s => s.identifier === value)
            : null,

    /**
     * Find stories by field and value
     * @param {object} state
     * @returns {array}
     */
    find: state => (field, value) =>
        state.initialised ? state.data.filter(s => s[field] === value) : [],
};

export default {
    namespaced: true,
    state,
    mutations,
    actions,
    getters,
};
