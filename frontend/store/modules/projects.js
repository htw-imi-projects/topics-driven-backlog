import { generate } from '@/store/base/resource-module/index';
import resources from '@/store/resources';

const resourceModule = generate({
    resource: resources.PROJECTS,
    parent: resources.COURSES,
    children: [resources.STORIES],
});

export default resourceModule;
