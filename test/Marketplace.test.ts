import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Signer, ContractFactory, Contract } from 'ethers'

describe('Marketplace', async () => {
    let signers: Signer[]
    let signerAddresses: String[]
    let MarketplaceFactory: ContractFactory
    let marketplace: Contract
    beforeEach(async () => {
        signers = await ethers.getSigners()
        signerAddresses = await Promise.all(signers.map((signer) => signer.getAddress()))

        MarketplaceFactory = await ethers.getContractFactory('Marketplace')
        marketplace = await MarketplaceFactory.deploy()
    })

    it('list username for purchase', async () => {
        await marketplace.setUsername('Joe.eth')
        await marketplace.listUsername(ethers.utils.parseEther('0.2'))
        expect(await marketplace.listingPrice('Joe.eth')).to.equal(ethers.utils.parseEther('0.2'))
    })
    it('list username and sell to other user', async () => {
        await marketplace.setUsername('Joe.eth')
        expect(await marketplace.getUsername(signerAddresses[0])).to.equal('Joe.eth')
        await marketplace.listUsername(ethers.utils.parseEther('0.2'))

        const signer0Balance = await signers[0].getBalance()
        const signer1Balance = await signers[1].getBalance()

        const buyTx = await marketplace.connect(signers[1]).populateTransaction.buyUsername(
            'Joe.eth',
            {
                value: ethers.utils.parseEther('0.2')
            }
        )
        const txReceipt = await (await signers[1].sendTransaction(buyTx)).wait()
        expect(marketplace.getUsername(signerAddresses[0]))
            .to.be.revertedWith('AccountDoesNotHaveAUsername')
        expect(await marketplace.getUsername(signerAddresses[1])).to.equal('Joe.eth')
        expect(await signers[0].getBalance()).to.equal(
            signer0Balance
                .add(ethers.utils.parseEther('0.2'))
        )
        expect(await signers[1].getBalance()).to.equal(
            signer1Balance
                .sub(ethers.utils.parseEther('0.2'))
                .sub(txReceipt.cumulativeGasUsed.mul(txReceipt.effectiveGasPrice))
        )
    })
    it('list username and unlist', async () => {
        await marketplace.setUsername('Joe.eth')
        await marketplace.listUsername(ethers.utils.parseEther('0.2'))
        expect(await marketplace.listingPrice('Joe.eth')).to.equal(ethers.utils.parseEther('0.2'))
        await marketplace.unlistUsername()
        expect(await marketplace.listingPrice('Joe.eth')).to.equal(ethers.BigNumber.from('0'))
    })
    it('cannot purchase unlisted username', async () => {
        expect(marketplace.connect(signers[1]).buyUsername('Joe.eth'))
            .to.be.revertedWith('UsernameHasNotBeenListed')
    })
    it('create bid for username', async () => {
        
    })
    it('increase bid for username', async () => {

    })
    it('decrease bid for username', async () => {

    })
    it('accept bid for username', async () => {
        
    })
})