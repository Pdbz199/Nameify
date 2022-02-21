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
})