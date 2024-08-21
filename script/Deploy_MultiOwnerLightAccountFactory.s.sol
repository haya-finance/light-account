// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";

import {MultiOwnerLightAccountFactory} from "../src/MultiOwnerLightAccountFactory.sol";

contract Deploy_MultiOwnerLightAccountFactory is Script {
    // Load entrypoint from env
    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    address public entryPointAddr = vm.envAddress("ENTRYPOINT");
    address public hayaToken = vm.envAddress("HAYA_CONTRACT_ADDRESS");
    address public paymaster = vm.envAddress("PAYMASTER_CONTRACT_ADDRESS");

    IEntryPoint public entryPoint = IEntryPoint(payable(entryPointAddr));

    // Load factory owner from env
    address public owner = vm.envAddress("OWNER");

    error InitCodeHashMismatch(bytes32 initCodeHash);
    error DeployedAddressMismatch(address deployed);

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        // Init code hash check
        bytes32 initCodeHash =
            keccak256(abi.encodePacked(type(MultiOwnerLightAccountFactory).creationCode, abi.encode(owner, entryPoint)));

        if (initCodeHash != 0x9ce10d22b464febda8c06cd72661aa53f096c10ce6389ac6d85175fc7c072a4f) {
            revert InitCodeHashMismatch(initCodeHash);
        }

        console.log("********************************");
        console.log("******** Deploy Inputs *********");
        console.log("********************************");
        console.log("Owner:", owner);
        console.log("Entrypoint:", address(entryPoint));
        console.log();
        console.log("********************************");
        console.log("******** Deploying.... *********");
        console.log("********************************");

        MultiOwnerLightAccountFactory factory = new MultiOwnerLightAccountFactory{
            salt: 0x0000000000000000000000000000000000000000bb3ab048b3f4ef2620ea0000
        }(owner, entryPoint);

        // Deployed address check
        if (address(factory) != 0x692d53919004F403f01305E930DEa9105463Bf09) {
            revert DeployedAddressMismatch(address(factory));
        }
        _initFactory(address(factory));
        _addStakeForFactory(address(factory));

        console.log("MultiOwnerLightAccountFactory:", address(factory));
        console.log("MultiOwnerLightAccount:", address(factory.ACCOUNT_IMPLEMENTATION()));
        console.log();

        vm.stopBroadcast();
    }

    function _initFactory(address factoryAddr) internal {
        MultiOwnerLightAccountFactory(payable(factoryAddr)).setGasTokenAndPaymaster(hayaToken, paymaster);
    }

    function _addStakeForFactory(address factoryAddr) internal {
        uint32 unstakeDelaySec = uint32(vm.envOr("UNSTAKE_DELAY_SEC", uint32(86400)));
        uint256 requiredStakeAmount = vm.envUint("REQUIRED_STAKE_AMOUNT");
        uint256 currentStakedAmount = entryPoint.getDepositInfo(factoryAddr).stake;
        uint256 stakeAmount = requiredStakeAmount - currentStakedAmount;
        MultiOwnerLightAccountFactory(payable(factoryAddr)).addStake{value: stakeAmount}(unstakeDelaySec, stakeAmount);
        console.log("******** Add Stake Verify *********");
        console.log("Staked factory: ", factoryAddr);
        console.log("Stake amount: ", entryPoint.getDepositInfo(factoryAddr).stake);
        console.log("Unstake delay: ", entryPoint.getDepositInfo(factoryAddr).unstakeDelaySec);
        console.log("******** Stake Verify Done *********");
    }
}
