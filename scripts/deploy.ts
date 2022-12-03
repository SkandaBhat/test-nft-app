import { ethers } from 'hardhat'
const hre = require('hardhat');

async function main() {
    const worldIDAddress = await fetch('https://developer.worldcoin.org/api/v1/contracts')
        .then(res => res.json() as Promise<{ key: string; value: string }[]>)
        .then(res => res.find(({ key }) => key === 'staging.semaphore.wld.eth').value)

    const trustedAddress: String = "0x69015912AA33720b842dCD6aC059Ed623F28d9f7"

    const ContractFactory = await ethers.getContractFactory('Contract')
    const contract = await ContractFactory.deploy(worldIDAddress, "wid_staging_f76caada4a091ea4b8423fa667be9f07", trustedAddress)

    await contract.deployed()

    const config = {
        address: contract.address,
        constructorArguments: [worldIDAddress, "wid_staging_f76caada4a091ea4b8423fa667be9f07", trustedAddress],
    };

    try {
        await hre.run('verify:verify', config);
    } catch (err) {
        console.error('Etherscan verification failed', err);
    }

    console.log('Contract deployed to:', contract.address)
}

main().catch(error => {
    console.error(error)
    process.exitCode = 1
})
