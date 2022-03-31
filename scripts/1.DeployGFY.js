const hre = require('hardhat')

async function main () {


	const accounts = await hre.ethers.getSigners()
	const GunfunnyTokenContract = await hre.ethers.getContractFactory('GunfunnyToken')

	const gfyToken = await GunfunnyTokenContract.deploy()
	await gfyToken.deployed()

	console.log('GunfunnyToken GFY token address: ', gfyToken.address)
    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error)
		process.exit(1)
	})
