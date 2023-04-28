<p align="center"><img src= "https://raw.githubusercontent.com/dapponics/uniforge/main/brand-assets/logos/png/Logo%20light.png" width="620" alt="Uniforge"></p>

# Uniforge Backend (public version)

## 1. Getting started

```
curl -L https://foundry.paradigm.xyz | bash

foundryup

forge init
```

## 2. Install the modules

```
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts
forge install chiru-labs/ERC721A
forge install ProjectOpenSea/operator-filter-registry
```

## 3. Update dependencies

```
forge update
```

## 4. Install the proper solc version

```
sudo nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_17
```

## 5. Build

```
forge build
```

## 6. Run tests

### 100% Coverage

```
forge coverage
```

### Unit Tests

```
forge test -vvv -m test_
```

### Fuzzing Tests

```
forge test -vvv -m testFuzz_
```

### Ethereum Mainnet Fork Tests

```
forge test -vvv -m testFork_
```

### Slither Tests

```
slither .
```

### Mythril Tests

```
myth analyze <solidity-file>
```

### Inspect Storage

```
forge inspect src/<solidity-file>:<contract-name> storage --pretty
```

### Gas Report

```
forge test --gas-report
```
