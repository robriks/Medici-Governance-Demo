decide on TOKEN.sol INIT() function (constructoresque)

  Plan GovernorVotes.sol implementation with ERC721Votes:
    -GovernorVotes.sol as module: GOVRN.sol / contract Governance {}
      -tallyGovernor policy is IGovernor (conforms to required Tally.xyz api (OZ governor) and gives user frontend)
        - rename tally.sol & all references to it to TallyGovernor
        ++proposalThreshold() function since that is required but not in Igovernor

Show and tell:

describe token module: ERC721Votes OZ (vs solmate 721) - describe delegation on mint, transfers, redelegation at any time
  - governance contract function ideas: setprotocolfee() / setPayoutAddress() 
  - discuss total supply
  - discuss mintTo() function: is it necessary
  - mention that Token module should have a better name than token
  - ask about whitelist plans (merkle tree contract refresher?)
describe GovernorVotes module:

config settings (that can be reconfigured after deployment but only via DAO vote)

    quorum: the number of votes (in this implementation, for votes) required to pass a proposal beyond voting

    votingDelay: the number of blocks a proposal needs to wait after creation to become active and allow voting. Usually set to zero, a longer delay gives people time to set up their votes before voting begins.

    votingPeriod: number of blocks to run the voting. A more extended period gives people more time to vote. Usually, DAOs set the period to somewhere between 3 and 6 days.
    quorum: the minimum number of 'Yes' votes needed for the proposal to pass. Usually, DAOs are set to 1–2% of the outstanding tokens, but a token with a wide distribution and few whales might want to put it lower.

    proposalThreshold: the minimum amount of voting power an address needs to create a proposal. A low threshold allows spam, but a high threshold makes proposals nearly impossible! DAOs are set to a number that will enable 5 or 10 of the largest token holders to create proposals.



link to add medici to tally:
https://www.tally.xyz/add-a-dao    
