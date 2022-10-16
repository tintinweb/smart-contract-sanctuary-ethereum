pragma solidity 0.8.13;

interface NekoNation {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function devMint(address to, uint256 amount) external;

    function approve(address to, uint256 tokenId) external payable;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);
}

contract NekoSwapper {
    address public NekonationContractAddress =
        0xcB190289aAd7D2941F109643C124D9cddF1f4E1D;
    NekoNation NekonationContract = NekoNation(NekonationContractAddress);
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");

    function contractHasSupportRole() public view returns (bool) {
        return NekonationContract.hasRole(SUPPORT_ROLE, address(this));
    }

    function approveSwapContractForTokenIdTransfer(uint256 oldtokenId) public {
        NekonationContract.approve(address(this), oldtokenId);
    }

    /// @notice Swaps old Nekonation token for new one
    /// @dev requires SUPPORT role granted to contract address, and takes the old Token, since burning is not possible
    /// @param oldTokenId tokenId that you want to swap for a new one
    function swap(uint256 oldTokenId) external {
        require(
            NekonationContract.hasRole(SUPPORT_ROLE, address(this)),
            "Support Role not given"
        );

        require(
            NekonationContract.ownerOf(oldTokenId) == msg.sender,
            "msg.sender not owner of tokenID"
        );

        NekonationContract.transferFrom(msg.sender, address(this), oldTokenId);
        NekonationContract.devMint(msg.sender, 1);
    }
}