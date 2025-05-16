// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BLSMintableERC20} from "../src/BLSMintableERC20.sol";
import {BN254} from "../src/libraries/BN254.sol";
import {BN254G2} from "../test/libraries/BN254G2.sol";

contract TestMintBLS is Script {
    using BN254 for BN254.G1Point;

    function run() public {
        // Get private keys from environment variables
        uint256 signer1Key = vm.envUint("SIGNER1_PRIVATE_KEY");
        uint256 signer2Key = vm.envUint("SIGNER2_PRIVATE_KEY");

        // Get the deployed contract address
        address deployedContract = vm.envAddress("DEPLOYED_CONTRACT");
        BLSMintableERC20 token = BLSMintableERC20(deployedContract);

        // Get recipient and amount from environment variables
        address recipient = vm.envAddress("RECIPIENT_ADDRESS");
        uint256 amount = 1000000000000000000; // 1 token with 18 decimals

        console2.log("Network:", vm.envString("SEPOLIA_RPC_URL"));
        console2.log("Deployed Contract:", deployedContract);
        console2.log("Recipient:", recipient);
        console2.log("Amount to mint:", amount);
        console2.log("Signer 1:", vm.addr(signer1Key));
        console2.log("Signer 2:", vm.addr(signer2Key));

        // Generate G1 public keys
        BN254.G1Point memory keyG1_1 = BN254.generatorG1().scalar_mul(signer1Key);
        BN254.G1Point memory keyG1_2 = BN254.generatorG1().scalar_mul(signer2Key);

        // Create array of G1 public keys
        BN254.G1Point[] memory pubkeysG1 = new BN254.G1Point[](2);
        pubkeysG1[0] = keyG1_1;
        pubkeysG1[1] = keyG1_2;

        // Generate G2 public keys separately and then aggregate
        BN254.G2Point memory g2Key1 = _getG2Key(signer1Key);
        BN254.G2Point memory g2Key2 = _getG2Key(signer2Key);
        BN254.G2Point memory aggregatedG2 = _aggregateG2Keys(g2Key1, g2Key2);

        // Generate signature
        bytes32 message = keccak256(abi.encode(recipient, amount));
        BN254.G1Point memory messageG1 = BN254.hashToG1(message);

        BN254.G1Point memory sigG1_1 = messageG1.scalar_mul(signer1Key);
        BN254.G1Point memory sigG1_2 = messageG1.scalar_mul(signer2Key);
        BN254.G1Point memory aggregatedSignature = sigG1_1.plus(sigG1_2);

        console2.log("\nFunction Parameters:");
        console2.log("recipient:", recipient);
        console2.log("amount:", amount);
        console2.log("\nG1 Public Keys:");
        console2.log("pubkeysG1[0].X:", pubkeysG1[0].X);
        console2.log("pubkeysG1[0].Y:", pubkeysG1[0].Y);
        console2.log("pubkeysG1[1].X:", pubkeysG1[1].X);
        console2.log("pubkeysG1[1].Y:", pubkeysG1[1].Y);
        console2.log("\nAggregated G2 Public Key:");
        console2.log("aggregatedG2.X[0]:", aggregatedG2.X[0]);
        console2.log("aggregatedG2.X[1]:", aggregatedG2.X[1]);
        console2.log("aggregatedG2.Y[0]:", aggregatedG2.Y[0]);
        console2.log("aggregatedG2.Y[1]:", aggregatedG2.Y[1]);
        console2.log("\nAggregated Signature:");
        console2.log("aggregatedSignature.X:", aggregatedSignature.X);
        console2.log("aggregatedSignature.Y:", aggregatedSignature.Y);

        // Encode the function call data
        bytes memory callData = abi.encodeWithSelector(
            token.mintWithBLSSignature.selector, recipient, amount, pubkeysG1, aggregatedG2, aggregatedSignature
        );
        console2.log("\nEncoded Function Call Data:");
        console2.log("0x", vm.toString(callData));

        // Start broadcasting transactions
        vm.startBroadcast();

        // Call mintWithBLSSignature
        token.mintWithBLSSignature(recipient, amount, pubkeysG1, aggregatedG2, aggregatedSignature);

        vm.stopBroadcast();

        console2.log("\nTransaction broadcasted");
    }

    function _getG2Key(uint256 privateKey) internal view returns (BN254.G2Point memory) {
        BN254.G2Point memory G2 = BN254.generatorG2();
        (uint256 x1, uint256 x2, uint256 y1, uint256 y2) =
            BN254G2.ECTwistMul(privateKey, G2.X[1], G2.X[0], G2.Y[1], G2.Y[0]);
        return BN254.G2Point([x2, x1], [y2, y1]);
    }

    function _aggregateG2Keys(BN254.G2Point memory key1, BN254.G2Point memory key2)
        internal
        view
        returns (BN254.G2Point memory)
    {
        // Add the G2 points directly instead of adding private keys
        (uint256 x1, uint256 x2, uint256 y1, uint256 y2) =
            BN254G2.ECTwistAdd(key1.X[1], key1.X[0], key1.Y[1], key1.Y[0], key2.X[1], key2.X[0], key2.Y[1], key2.Y[0]);
        return BN254.G2Point([x2, x1], [y2, y1]);
    }
}
