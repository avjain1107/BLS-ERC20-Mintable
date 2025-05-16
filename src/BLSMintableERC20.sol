// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {BLSSig} from "./BLS/BLSSig.sol";
import {BN254} from "./libraries/BN254.sol";
import {IBLSMintableERC20} from "./interfaces/IBLSMintableERC20.sol";

contract BLSMintableERC20 is ERC20, Ownable, BLSSig, IBLSMintableERC20 {
    using BN254 for BN254.G1Point;

    mapping(bytes32 => bool) public usedMessages;

    constructor(string memory name, string memory symbol, address owner) ERC20(name, symbol) Ownable(owner) {}

    /// @notice Verifies a BLS signature and mints tokens to recipient if valid
    /// @param recipient Address to mint tokens to
    /// @param amount Amount of tokens to mint
    /// @param pubkeysG1 Array of individual G1 public keys (signers)
    /// @param aggregatedPubkeyG2 Aggregated G2 public key
    /// @param aggregatedSignature Aggregated BLS signature
    function mintWithBLSSignature(
        address recipient,
        uint256 amount,
        BN254.G1Point[] memory pubkeysG1,
        BN254.G2Point memory aggregatedPubkeyG2,
        BN254.G1Point memory aggregatedSignature
    ) external override {
        bytes32 message = keccak256(abi.encode(recipient, amount));

        require(!usedMessages[message], "Message already used");
        usedMessages[message] = true;

        // Aggregate individual G1 public keys
        BN254.G1Point memory aggregatedG1 = pubkeysG1[0];
        for (uint256 i = 1; i < pubkeysG1.length; i++) {
            aggregatedG1 = aggregatedG1.plus(pubkeysG1[i]);
        }

        // Verify the signature
        bool valid = verify(aggregatedG1, aggregatedPubkeyG2, aggregatedSignature, message);
        require(valid, "Invalid BLS signature");

        _mint(recipient, amount);
    }
}
