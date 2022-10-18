-convert erc20 governance token to erc721Votes from OZ

decide on TOKEN.sol INIT() function (constructoresque)

  Plan GovernorVotes.sol implementation with ERC721Votes:
    -GovernorVotes.sol as module: GOVRN.sol / contract Governance {}
      -tallyGovernor policy is IGovernor (conforms to required Tally.xyz api (OZ governor) and gives user frontend)
        - rename tally.sol & all references to it to TallyGovernor
        ++proposalThreshold() function since that is required but not in Igovernor

Show and tell:

describe token module: ERC721Votes OZ (vs solmate 721) - describe its delegation implementation
  - clarify policy vs module wrt tokens: a matter of managing permissions
  - discuss total supply
  - discuss mintTo() function: is it necessary
  - mention that Token module should have a better name than token
describe GovernorVotes module

    
