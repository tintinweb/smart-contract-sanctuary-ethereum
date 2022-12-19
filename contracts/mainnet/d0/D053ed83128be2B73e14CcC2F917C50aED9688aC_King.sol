// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.1;

contract King {
    address owner;
    bool public isPayable = false;
    address kingAddress;
    uint32 kingId;
    string kingName;
    string kingAsset;
    string kingPossession;
    uint256 timestamp;
    uint256 payed;

    constructor(string memory _asset) {
        kingAddress = msg.sender;
        kingId = 0;
        kingName = unicode"Þórður";
        kingPossession = "livepoints.net";
        kingAsset = _asset;
        payed = 0;
        owner = msg.sender;
        timestamp = block.timestamp;
    }

    event HailTheNewKing(
        address kingAddress,
        uint32 kingId,
        string kingName,
        string kingAsset,
        string kingPossession,
        uint256 payed,
        uint256 timestamp
    );

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function _checkOwner() internal view virtual {
        require(msg.sender == owner, "Ownable: caller is not the owner");
    }

    function crownNewKing(string calldata _king, string calldata _asset, string calldata _kingPossession)
        external
        payable
    {
        require(
            !isPayable || payed < msg.value,
            "Payed value is less than needed"
        );
        kingAddress = msg.sender;
        kingId = kingId + 1;
        kingName = _king;
        kingAsset = _asset;
        payed = msg.value;
        kingPossession = _kingPossession;
        timestamp = block.timestamp;
        emit HailTheNewKing(kingAddress, kingId, kingName, kingAsset,kingPossession, payed, timestamp);
    }

    function changePayable( bool _isPayable)
        external
        onlyOwner
    {
        isPayable = _isPayable;
    }

    function payout(address _payoutAddress) external onlyOwner {
        (bool sent, ) = _payoutAddress.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function whoSitsTheThrone()
        external
        view
        returns (
            address _kingAddress,
            uint32 _kingId,
            string memory _kingName,
            string memory _kingAsset,
            string memory _kingPossession,
            uint256 _payed,
            uint256 _timestamp
        )
    {
        return (kingAddress, kingId, kingName, kingAsset,kingPossession, payed, timestamp);
    }
}