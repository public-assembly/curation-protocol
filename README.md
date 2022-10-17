# Public Curation Protocol

### High-level overview
1. Individual curation contracts are ERC721 collections themselves, with curators receiving a non-transferable `listingRecord` that contains the information of the `Listing` they have curated. Curators can "remove" a Listing by burning their listingRecords
2. Factory allows for easy creation of individual curation contracts
3. Active Listings on a given curation contract can be retrieved by the `getListings()` view call on a given **Curator.sol** proxy, or by using NFT indexers to gather data on all `curationReciepts` that have been minted from a given curation contract
4. Listings contain the data specified in the `Listing` struct found in [ICurator.sol](https://github.com/public-assembly/curation-protocol/blob/main/src/interfaces/ICurator.sol)

### Features these contracts support:

1. Deploying your own ERC721 curation contract
2. Curation of certain "types" of Ethereum addresses. Current types include:
- NFT Contract
- Generic smart contracts
- Other curation contracts
- Specific tokens of an NFT contract
- Wallet addresses (EOA or smart contract)
- ZORA ERC721DROP collections
3. Restricted curation access gated by a set ERC721 collection (ex: user balance > 0 of ERC721 provides access to curation functionality)
4. Curation listings represented as individual non-transferable `listingRecord` NFTs minted to a curator's wallet. Allows for easy tracking via NFT indexers (like the [ZORA API](https://api.zora.co/)
5. Ability for curators to remove their `Listings` by burning their non-transferable `listingRecords`


### What are these contracts?
1. `CuratorSkeletonNFT.sol`
   Each curation contract is its own ERC721 collection. This allows for clear contract ownership, listings as individual tokens that are minted out of the contract, and composability with NFT indexers
2. `Curator.sol`
   Base implementaion for curation contracts generated from **CuratorFactory.sol**. Inherits from **CuratorSkeletonNFT**, and manages all of the curation related functionality  
3. `CuratorFactory.sol`
   Gas-optimized factory contract allowing you to easily + for a low gas transaction to create your own curation contract.   
4. `DefaultMetadataRenderer`
   A flexible metadata renderer architecture that allows for centralised and IPFS metadata group roots to be rendered.
5. `SVGMetadataRenderer`
   Onchain renderer for curation contracts that encodes information related to a specific listing

### How do I use this in my site?

1. Use wagmi/ethers/web3.js with the given artifacts (in the node package) or typechain.
2. Check out the [@public-assembly/curation-interactions](https://www.npmjs.com/package/@public-assembly/curation-interactions) package for custom hooks + components designed to simplify contract interactions
3. Check out the [Neosound](https://github.com/public-assembly/neosound) repo for an example application built on top of the curation protocol
4. Check out this quickstart [doc](https://docs.google.com/document/d/1pD7kf5OsY_80oqTEQy6BTJZ4v22cnZ-1kT8d3vU5Gbw/edit) for notes + video on how to start experimenting with the curation protcol from both a solidity + UI level

### Local development

1. Install [Foundry](https://github.com/foundry-rs/foundry)
2. `yarn install`
3. `git submodule init && git submodule update`
4. `yarn build` 

### Flexibility and safety

All curation contracts are wholly owned by their creator and allow for extensibility with rendering and minting

All curation listing tokens minted to curators are non-transferable, but allow for the curator to burn the token so as to remove it from the onchain listing and their wallet

The metadata renderer abstraction allows these drops contracts to power a variety of on-chain powered projects
