// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BN254} from "../libraries/BN254.sol";

interface IBLSMintableERC20 is IERC20 {
    /**
     * @notice Verifies a BLS signature and mints tokens to recipient if valid
     * @param recipient Address to mint tokens to
     * @param amount Amount of tokens to mint
     * @param pubkeysG1 Array of individual G1 public keys (signers)
     * @param aggregatedPubkeyG2 Aggregated G2 public key
     * @param aggregatedSignature Aggregated BLS signature
     */
    function mintWithBLSSignature(
        address recipient,
        uint256 amount,
        BN254.G1Point[] memory pubkeysG1,
        BN254.G2Point memory aggregatedPubkeyG2,
        BN254.G1Point memory aggregatedSignature
    ) external;

    /**
     * @notice Checks if a message has been used for minting
     * @param message The message hash to check
     * @return bool True if the message has been used, false otherwise
     */
    function usedMessages(bytes32 message) external view returns (bool);
}
