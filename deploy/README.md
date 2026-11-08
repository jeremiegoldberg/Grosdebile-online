# Déploiement

Les environnements de développement utiliseront Docker Compose ; les déploiements persistants pourront utiliser Kubernetes.

À prévoir :
- Service Luanti en UDP (LoadBalancer/MetalLB ou mécanisme équivalent).
- Ingress HTTP/HTTPS séparé pour le portail et les API.
- PostgreSQL avec volume persistant, sauvegardes et restauration testée.
- Secrets hors Git.
- Ressources, probes, politiques réseau et observabilité.
- Images construites de manière reproductible et versions épinglées.

Aucun manifeste de production n'est fourni à ce stade.
