/* solhint-disable */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {CrowdFund} from "../../contracts/CrowdFund.sol";
import {console2} from "forge-std/console2.sol";

contract DeployCrowdFund is Script {
    function run() external returns (CrowdFund crowdFund) {
        vm.startBroadcast();
        crowdFund = new CrowdFund();
        vm.stopBroadcast();

        console2.log("CrowdFund deployed at:", address(crowdFund));
        console2.log("CrowdFund deployed by:", msg.sender);
        console2.log("CrowdFund deployed at block:", block.number);
        return crowdFund;    
    }
}