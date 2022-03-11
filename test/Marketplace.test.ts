import { expect } from 'chai'
import { waffle, ethers } from 'hardhat'
import { Signer, ContractFactory, Contract } from 'ethers'

describe('Marketplace', async () => {
    let signers: Signer[]
    let signerAddresses: string[]
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
        const username = 'Joe.eth'
        await marketplace.setUsername(username)

        const bidAmount = ethers.utils.parseEther('2') // 2 AVAX
        await marketplace.connect(signers[1]).makeBid(username, { value: bidAmount })
        expect(await marketplace.getHighestBidAmount(username)).to.equal(bidAmount)
        expect(await marketplace.connect(signers[1]).getBidAmount(username)).to.equal(bidAmount)
    })
    it('increase bid for username', async () => {
        const username = 'Joe.eth'
        await marketplace.setUsername(username)

        const bidAmount = ethers.utils.parseEther('2') // 2 AVAX
        await marketplace.connect(signers[1]).makeBid(username, { value: bidAmount })

        await marketplace.connect(signers[1]).makeBid(username, { value: bidAmount.div(2) })
        expect(await marketplace.getHighestBidAmount(username)).to.equal(bidAmount.add(bidAmount.div(2)))
    })
    it('remove bid for username', async () => {
        const username = 'Joe.eth'
        await marketplace.setUsername(username)

        const bidAmount = ethers.utils.parseEther('2') // 2 AVAX
        await marketplace.connect(signers[1]).makeBid(username, { value: bidAmount })

        const balanceBefore = await waffle.provider.getBalance(signerAddresses[1])
        expect((await marketplace.getHighestBidAmount(username)).isZero()).to.be.false
        await marketplace.connect(signers[1]).removeBid(username)
        const balanceAfter = await waffle.provider.getBalance(signerAddresses[1])
        expect(balanceAfter.lt(balanceBefore.add(bidAmount))).to.be.true
        expect(balanceAfter.gte(balanceBefore.sub(ethers.utils.parseUnits('800', 12)).add(bidAmount))).to.be.true
        expect((await marketplace.getHighestBidAmount(username)).isZero()).to.be.true
        expect(marketplace.acceptHighestBid()).to.be.revertedWith('ThereIsNoHighestBidder')
    })
    it('accept bid for username', async () => {
        const username = 'Joe.eth'
        await marketplace.setUsername(username)

        const bidAmount = ethers.utils.parseEther('2') // 2 AVAX
        await marketplace.connect(signers[1]).makeBid(username, { value: bidAmount })

        const balanceBefore = await waffle.provider.getBalance(signerAddresses[0])
        expect(await marketplace.getUsername(signerAddresses[0])).to.equal(username)
        expect(marketplace.getUsername(signerAddresses[1])).to.be.revertedWith('AccountDoesNotHaveAUsername')
        expect(await marketplace.getAddress(username)).to.equal(signerAddresses[0])
        await marketplace.acceptHighestBid()
        const balanceAfter = await waffle.provider.getBalance(signerAddresses[0])
        expect(balanceAfter.gt(balanceBefore.add(bidAmount).sub(ethers.utils.parseEther('0.0001')))).to.be.true
        expect(marketplace.getUsername(signerAddresses[0])).to.be.revertedWith('AccountDoesNotHaveAUsername')
        expect(await marketplace.getUsername(signerAddresses[1])).to.equal(username)
        expect(await marketplace.getAddress(username)).to.equal(signerAddresses[1])
    })
})