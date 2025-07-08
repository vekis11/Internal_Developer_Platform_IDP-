import { createPlugin } from '@backstage/core-plugin-api';
import { createRoutableExtension } from '@backstage/core-plugin-api';
import { rootRouteRef } from './routes';

export const idpDashboardPlugin = createPlugin({
  id: 'idp-dashboard',
  routes: {
    root: rootRouteRef,
  },
});

export const IdpDashboardPage = idpDashboardPlugin.provide(
  createRoutableExtension({
    name: 'IdpDashboardPage',
    component: () => import('./components/IdpDashboardPage').then(m => m.IdpDashboardPage),
    mountPoint: rootRouteRef,
  }),
); 