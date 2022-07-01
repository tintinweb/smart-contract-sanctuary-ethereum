/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

pragma solidity 0.8.3;

library PineLendingLibrary {
  struct LoanTerms {
    uint256 loanStartBlock;
    uint256 loanExpireTimestamp;
    uint32 interestBPS1000000XBlock;
    uint32 maxLTVBPS;
    uint256 borrowedWei;
    uint256 returnedWei;
    uint256 accuredInterestWei;
    uint256 repaidInterestWei;
    address borrower;
    }

  function outstanding(LoanTerms calldata loanTerms, uint txSpeedBlocks) public view returns (uint256) {
    // do not lump the interest
    if (loanTerms.borrowedWei <= loanTerms.returnedWei) return 0;
    uint256 newAccuredInterestWei = ((block.number + txSpeedBlocks -
        loanTerms.loanStartBlock) *
        (loanTerms.borrowedWei - loanTerms.returnedWei) *
        loanTerms.interestBPS1000000XBlock) / 10000000000;
    return
        (loanTerms.borrowedWei - loanTerms.returnedWei) +
        (loanTerms.accuredInterestWei -
            loanTerms.repaidInterestWei) +
        newAccuredInterestWei;
  }

  function outstanding(LoanTerms calldata loanTerms) public view returns (uint256) {
    return outstanding(loanTerms, 0);
  }

  function nftHasLoan(LoanTerms memory loanTerms) public pure returns (bool) {
      return loanTerms.borrowedWei > loanTerms.returnedWei;
  }


  function isUnHealthyLoan(LoanTerms calldata loanTerms)
      public
      view
      returns (bool, uint32)
  {
      require(nftHasLoan(loanTerms), "nft does not have active loan");
      bool isExpired = block.timestamp > loanTerms.loanExpireTimestamp &&
          outstanding(loanTerms) > 0;
      return (isExpired, 0);
  }

  event LoanInitiated(
      address indexed user,
      address indexed erc721,
      uint256 indexed nftID,
      LoanTerms loan
  );
  event LoanTermsChanged(
      address indexed user,
      address indexed erc721,
      uint256 indexed nftID,
      LoanTerms oldTerms,
      LoanTerms newTerms
  );
  event Liquidation(
      address indexed user,
      address indexed erc721,
      uint256 indexed nftID,
      uint256 liquidated_at,
      address liquidator
  );
}