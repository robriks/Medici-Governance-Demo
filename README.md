# Demo of Medici governance ERC20 token using Default framework
### by 👦🏻👦🏻.eth

This repo demonstrates a working implementation of an ERC20 governance token using the Default framework. It can easily be modified to use ERC721 tokens for governance as well as inherit the OpenZeppelin Governor.sol contract to be used with the popular Tally.xyz frontend. More on the Default Kernel and Tally below.

## To view demonstration

This repo is built with Foundry, so first ensure that it is installed! To demo, run the token test contract:

```forge test -vvvv --match-contract TokenTest```

Note that dependencies may first need to be installed with ```forge install```


## Default Kernel

The Default kernel draws inspiration from more mature computer science fields like web development and operating system structures. It organizes moving parts into internal logic contracts (ie backend) called modules and external facing user-accessible contracts (ie frontend) called policies. The access and execution flow of function calls from users and between policies/modules is centrally managed by a single contract: Kernel.sol. All contracts in the framework, including the central Kernel contract itself, are upgradeable.

The Default Framework's main advantage lies in one factor: ease of development. The status quo of web3 is a disorganized mess of complex protocols that require dedicated time and effort to comprehend, much less build code on top of. Default's standardized structure of upgradeable internal and external components managed centrally means developers need only learn one contract: the Kernel. Like a major operating system (ie linux, ios, android), Default is easy for a developer to work with in the context of various protocols after it's been learned once.

### Cheatsheet
keycode == custom type that points to specific modules
admin == team member who grants roles
executor == team member who handles kernel policy/module upgrades
roles == custom type that handles access control for both users and contracts across policies + modules
dependencies == modules used by policies
permissions == struct that handles access control for policy contracts to use specific module dependency functions


## Governance

Tally.xyz is the foremost on-chain governance frontend platform: it serves as a governance hub for multiple DAOs while giving users a way to directly interface with governance contracts (voting, proposing) and while providing a whole host of useful frontend features like data visualization. DAOs that use Tally as their governance frontend include: ENS DAO, Gitcoin, NounsDAO, Compound, Hop Protocol DAO, Reflexer RAI, and many other reputable decentralized organizations. 

Web3 governance is in need of a standardized approach to governance to help users gain familiarity with democratically participating in DAOs and Tally accomplishes exactly that. For these reasons, it is beneficial to Medici to use contracts compatible with Tally to gain visibility to web3 natives who participate in other DAOs as well as build relevant, familiar governance habits within the Medici community that can be used in other similar web3 organizations.

Which contracts are compatible with Tally?
Any custom contracts- the implementation is up to us so long as it inherits OpenZeppelin Governor.sol

The challenge at hand: write Medici's governance contracts in a way that utilizes benefits of the Default framework while still remaining compatible with Tally.xyz