# BLS Mintable ERC20 Token

This project demonstrates an ERC20 token with BLS-based signature minting, allowing authorized parties to mint tokens using BLS (Boneh-Lynn-Shacham) signatures. This is useful for scalable and gas-efficient batch approvals in decentralized systems.

## Deployment & Verification

### 1. Deploy BLSMintableERC20 to Sepolia

Run the deployment script:

```bash
forge script script/DeployBLSMintableERC20.s.sol:DeployBLSMintableERC20 \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv
```

**Deployed Contract (Sepolia):** [0x6a762D8374674674452A749738399a76e0EbEAeB384](https://sepolia.etherscan.io/address/0x6a762d8374674452a749738399a76e0ebeaeb384)

### 2. Mint Tokens Using BLS Signatures

To mint tokens with a valid BLS signature, run:

```bash
forge script script/TestMintBLS.s.sol:TestMintBLS \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    -vvvv
```

## Contract Functions

| Function | Description |
|----------|-------------|
| `mintWithBLSSignature(address to, uint256 amount, BN254.G1Point[] memory pubkeysG1, BN254.G2Point memory aggregatedG2, BN254.G1Point memory signature)` | Mints tokens if the BLS signature is valid. Requires G1 public keys, aggregated G2 public key, and the aggregated signature. |

## Environment Variables

Create a `.env` file with the following variables:

```env
PRIVATE_KEY
SEPOLIA_RPC_URL
ETHERSCAN_API_KEY
SIGNER1_PRIVATE_KEY
SIGNER2_PRIVATE_KEY
DEPLOYED_CONTRACT
RECIPIENT_ADDRESS
```

## Testing

To run the test suite:

```bash
forge test -vvv
```

## License

MIT