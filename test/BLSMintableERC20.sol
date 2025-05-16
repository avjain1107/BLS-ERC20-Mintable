// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {BLSMintableERC20} from "../src/BLSMintableERC20.sol";
import {BN254} from "../src/libraries/BN254.sol";
import {BN254G2} from "../test/libraries/BN254G2.sol";

contract BLSMintableERC20Test is Test {
    using BN254 for BN254.G1Point;

    BLSMintableERC20 public token;
    address public owner;
    address public recipient;

    address attester1;
    address attester2;
    address attester3;

    uint256 attester1Key;
    uint256 attester2Key;
    uint256 attester3Key;

    function setUp() public {
        owner = makeAddr("owner");
        recipient = makeAddr("recipient");

        (attester1, attester1Key) = makeAddrAndKey("attester1");
        (attester2, attester2Key) = makeAddrAndKey("attester2");
        (attester3, attester3Key) = makeAddrAndKey("attester3");

        vm.startPrank(owner);
        token = new BLSMintableERC20("BLS Token", "BLS", owner);
        vm.stopPrank();
    }

    function _setupBLSKeys()
        internal
        view
        returns (
            BN254.G1Point[] memory pubkeysG1,
            BN254.G2Point memory aggregatedG2,
            BN254.G1Point memory aggregatedSignature
        )
    {
        BN254.G1Point memory keyG1_1 = BN254.generatorG1().scalar_mul(attester1Key);
        BN254.G1Point memory keyG1_2 = BN254.generatorG1().scalar_mul(attester2Key);
        BN254.G1Point memory keyG1_3 = BN254.generatorG1().scalar_mul(attester3Key);

        pubkeysG1 = new BN254.G1Point[](3);
        pubkeysG1[0] = keyG1_1;
        pubkeysG1[1] = keyG1_2;
        pubkeysG1[2] = keyG1_3;

        uint256 sumKey = attester1Key + attester2Key + attester3Key;
        aggregatedG2 = _getG2Key(sumKey);

        return (pubkeysG1, aggregatedG2, aggregatedSignature);
    }

    function _createBLSSignature(uint256 amount) internal view returns (BN254.G1Point memory) {
        bytes32 message = keccak256(abi.encode(recipient, amount));
        BN254.G1Point memory messageG1 = BN254.hashToG1(message);

        BN254.G1Point memory sigG1_1 = messageG1.scalar_mul(attester1Key);
        BN254.G1Point memory sigG1_2 = messageG1.scalar_mul(attester2Key);
        BN254.G1Point memory sigG1_3 = messageG1.scalar_mul(attester3Key);

        return sigG1_1.plus(sigG1_2).plus(sigG1_3);
    }

    function _getG2Key(uint256 privateKey) internal view returns (BN254.G2Point memory) {
        BN254.G2Point memory G2 = BN254.generatorG2();
        (uint256 x1, uint256 x2, uint256 y1, uint256 y2) =
            BN254G2.ECTwistMul(privateKey, G2.X[1], G2.X[0], G2.Y[1], G2.Y[0]);
        return BN254.G2Point([x2, x1], [y2, y1]);
    }

    function testMintWithValidBLSSignature() public {
        uint256 amount = 1000;

        (BN254.G1Point[] memory pubkeysG1, BN254.G2Point memory aggregatedG2,) = _setupBLSKeys();
        BN254.G1Point memory aggregatedSignature = _createBLSSignature(amount);

        assertEq(token.balanceOf(recipient), 0);

        token.mintWithBLSSignature(recipient, amount, pubkeysG1, aggregatedG2, aggregatedSignature);

        assertEq(token.balanceOf(recipient), amount);
    }

    function testCannotDoubleMintWithSameMessage() public {
        uint256 amount = 1000;

        (BN254.G1Point[] memory pubkeysG1, BN254.G2Point memory aggregatedG2,) = _setupBLSKeys();
        BN254.G1Point memory aggregatedSignature = _createBLSSignature(amount);

        token.mintWithBLSSignature(recipient, amount, pubkeysG1, aggregatedG2, aggregatedSignature);

        vm.expectRevert("Message already used");
        token.mintWithBLSSignature(recipient, amount, pubkeysG1, aggregatedG2, aggregatedSignature);
    }

    function testMintWithInvalidBLSSignature() public {
        uint256 amount = 1000;

        (BN254.G1Point[] memory pubkeysG1, BN254.G2Point memory aggregatedG2,) = _setupBLSKeys();

        // Create an invalid signature by using a different message
        bytes32 invalidMessage = keccak256(abi.encode(recipient, amount + 1));
        BN254.G1Point memory invalidMessageG1 = BN254.hashToG1(invalidMessage);
        BN254.G1Point memory invalidSigG1_1 = invalidMessageG1.scalar_mul(attester1Key);
        BN254.G1Point memory invalidSigG1_2 = invalidMessageG1.scalar_mul(attester2Key);
        BN254.G1Point memory invalidSigG1_3 = invalidMessageG1.scalar_mul(attester3Key);
        BN254.G1Point memory invalidSignature = invalidSigG1_1.plus(invalidSigG1_2).plus(invalidSigG1_3);

        vm.expectRevert("Invalid BLS signature");
        token.mintWithBLSSignature(recipient, amount, pubkeysG1, aggregatedG2, invalidSignature);
    }
}
