# Staking contract

Контракт для стейка нативных токенов блокчейнов. 

### Методы: 
 - setParams - оунер задает процент награды для стейка для определенной отрезка времени. Если передается существующий отрезок времени для стейка и 0 в качестве награды, то этот перииод становиться неактивным.
 - getDepositeInfo - вывод инфы о стейке. 
 - createDeposit - для создания стейка, входящий параметр время в минутах.
 - withdrawDeposit - для вывода стейка

```shell
npx i
npx hardhat test
```
