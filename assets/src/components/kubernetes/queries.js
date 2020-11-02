import { gql } from 'apollo-boost'
import { DeploymentFragment, IngressFragment, ServiceFragment, StatefulSetFragment } from '../graphql/kubernetes';

export const SERVICE_Q = gql`
  query Service($name: String!, $namespace: String!) {
    service(name: $name, namespace: $namespace) { ...ServiceFragment }
  }
  ${ServiceFragment}
`;

export const DEPLOYMENT_Q = gql`
  query Deployment($name: String!, $namespace: String!) {
    deployment(name: $name, namespace: $namespace) { ...DeploymentFragment }
  }
  ${DeploymentFragment}
`;

export const INGRESS_Q = gql`
  query Ingress($name: String!, $namespace: String!) {
    ingress(name: $name, namespace: $namespace) { ...IngressFragment }
  }
  ${IngressFragment}
`;

export const STATEFUL_SET_Q = gql`
  query StatefulSet($name: String!, $namespace: String!) {
    statefulSet(name: $name, namespace: $namespace) { ...StatefulSetFragment }
  }
  ${StatefulSetFragment}
`;