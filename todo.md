-convert erc20 governance token to erc721Votes from OZ
  Plan GovernorVotes.sol implementation with ERC721Votes:
    -GovernorVotes.sol as module
      -tallyGovernor policy is IGovernor (conforms to required Tally.xyz api (OZ governor) and gives user frontend)
        ++proposalThreshold() function since that is required but not in Igovernor
    -ERC721Votes as token module ++requires a delegate method
    
