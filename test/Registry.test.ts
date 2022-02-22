import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Signer, ContractFactory, Contract } from 'ethers'

describe('Registry', async () => {
    let signers: Signer[]
    let signerAddresses: String[]
    let RegistryFactory: ContractFactory
    let registry: Contract
    beforeEach(async () => {
        signers = await ethers.getSigners()
        signerAddresses = await Promise.all(signers.map((signer) => signer.getAddress()))

        RegistryFactory = await ethers.getContractFactory('Registry')
        registry = await RegistryFactory.deploy()
    })

    it('deploys', async () => {
        expect(registry.address).to.not.equal(ethers.constants.AddressZero)
    })
    it('creates username', async () => {
        await registry.setUsername('Joe.eth')
        expect(await registry.getUsername(signerAddresses[0])).to.equal('Joe.eth')
        expect(await registry.getAddress('Joe.eth')).to.equal(signerAddresses[0])
    })
    it('overwrites username', async () => {
        await registry.setUsername('Joe.eth')
        await registry.setUsername('JOE.eth')
        expect(registry.getAddress('Joe.eth')).to.be.revertedWith('UsernameHasNotBeenSet')
        expect(await registry.getUsername(signerAddresses[0])).to.equal('JOE.eth')
        expect(await registry.getAddress('JOE.eth')).to.equal(signerAddresses[0])
    })
    it('changes username', async () => {
        await registry.setUsername('Joe.eth')
        expect(await registry.getUsername(signerAddresses[0])).to.equal('Joe.eth')

        await registry.setUsername('JOE.eth')
        const currentUsername = await registry.getUsername(signerAddresses[0])

        expect(currentUsername).to.not.equal('Joe.eth')
        expect(currentUsername).to.equal('JOE.eth')
    })
    it('remove username', async () => {
        await registry.setUsername('Joe.eth')
        expect(await registry.getUsername(signerAddresses[0])).to.equal('Joe.eth')
        
        await registry.removeUsername()
        expect(registry.getUsername(signerAddresses[0]))
            .to.be.revertedWith('AccountDoesNotHaveAUsername')
    })
    it('ensures username uniqueness', async () => {
        await registry.setUsername('Joe.eth')
        expect(registry.connect(signers[1]).setUsername('Joe.eth'))
            .to.be.revertedWith('UsernameAlreadyExists')
    })
    it('tests getter functions before any setters', async () => {
        expect(registry.getUsername(signerAddresses[0]))
            .to.be.revertedWith('AccountDoesNotHaveAUsername')

        expect(registry.getAddress('Joe.eth'))
                .to.be.revertedWith('UsernameHasNotBeenSet')
    })
    it('cannot remove username before creating one', async () => {
        expect(registry.removeUsername())
            .to.be.revertedWith('AccountDoesNotHaveAUsername')
    })
    it('list username for purchase', async () => {
        await registry.setUsername('Joe.eth')
        await registry.listUsername(ethers.utils.parseEther('0.2'))
        expect(await registry.listingPrice('Joe.eth')).to.equal(ethers.utils.parseEther('0.2'))
    })
    it('list username and sell to other user', async () => {
        await registry.setUsername('Joe.eth')
        expect(await registry.getUsername(signerAddresses[0])).to.equal('Joe.eth')
        await registry.listUsername(ethers.utils.parseEther('0.2'))

        const signer0Balance = await signers[0].getBalance()
        const signer1Balance = await signers[1].getBalance()

        const buyTx = await registry.connect(signers[1]).populateTransaction.buyUsername(
            'Joe.eth',
            {
                value: ethers.utils.parseEther('0.2')
            }
        )
        const txReceipt = await (await signers[1].sendTransaction(buyTx)).wait()
        expect(registry.getUsername(signerAddresses[0])).to.be.revertedWith('AccountDoesNotHaveAUsername')
        expect(await registry.getUsername(signerAddresses[1])).to.equal('Joe.eth')
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
        await registry.setUsername('Joe.eth')
        await registry.listUsername(ethers.utils.parseEther('0.2'))
        expect(await registry.listingPrice('Joe.eth')).to.equal(ethers.utils.parseEther('0.2'))
        await registry.unlistUsername()
        expect(await registry.listingPrice('Joe.eth')).to.equal(ethers.BigNumber.from('0'))
    })
    it('cannot purchase unlisted username', async () => {
        expect(registry.connect(signers[1]).buyUsername('Joe.eth'))
            .to.be.revertedWith('UsernameHasNotBeenListed')
    })
})