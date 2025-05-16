// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BLSMintableERC20} from "../src/BLSMintableERC20.sol";

contract DeployBLSMintableERC20 is Script {
    function run() public {
        // Get the private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get the deployer address
        address deployer = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        BLSMintableERC20 token = new BLSMintableERC20(
            "BLS Token", // name
            "BLS", // symbol
            deployer // owner
        );

        vm.stopBroadcast();

        // Log the deployed address and deployer
        console2.log("Deployer:", deployer);
        console2.log("BLSMintableERC20 deployed at:", address(token));
    }
}
