// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockBox {
    struct Box {
        bytes boxId;
        address creator;
        string creatorNickname;
        uint totalTokenAmount;
        uint tokenAmount;
        uint participantsLimit;
        address[] participants;
        uint[] participantsPrize;
        string message;
        uint creationTime;
    }
    mapping(bytes => Box) box;
    mapping(address => bytes[]) public receiverToBox;
    mapping(address => bytes[]) public creatorToBox;

    event BoxCreated(bytes boxId);
    event Claimed(bool claimed);
    event CreatorWithdrawn(bool withdrawn);

    constructor() {}

    /********************************************************
     *                                                       *
     *                     MAIN FUNCTIONS                    *
     *                                                       *
     ********************************************************/

    /// @notice create an box and share money with your people
    /// @param _message welcome message of the box
    /// @dev creates box and stores crypto in this contract to later on distribute with participants
    function createBox(
        uint _participantsLimit,
        string memory _message,
        string memory _creatorNickName
    ) external payable returns (bytes memory _boxId) {
        require(msg.value > 0, "Insufficient funds");
        _boxId = abi.encode(msg.sender, block.timestamp);
        box[_boxId].boxId = _boxId;
        box[_boxId].creator = msg.sender;
        box[_boxId].creatorNickname = _creatorNickName;
        box[_boxId].totalTokenAmount = msg.value;
        box[_boxId].tokenAmount = msg.value;
        box[_boxId].participantsLimit = _participantsLimit;
        box[_boxId].message = _message;
        box[_boxId].creationTime = block.timestamp;
        creatorToBox[msg.sender].push(_boxId);
        emit BoxCreated(_boxId);
    }

    /// @notice Open box before others and get crypto gift!
    /// @param _boxId id of box in bytes256
    /// @dev contract distributes crypto to msg.sender
    function claim(bytes memory _boxId) external {
        Box storage _box = box[_boxId];
        uint _currentParticipant = _box.participants.length;
        require(
            _box.participantsLimit > _currentParticipant,
            "max participants exceeded"
        );
        require(_box.tokenAmount > 0, "tokens already distributed");
        _box.participants.push() = msg.sender;
        uint _amountToDeliver;
        // If it is the last possible participant it shares the remaining crypto. Otherwise it shares a random amount of crypto
        if (_box.participantsLimit != _currentParticipant) {
            _amountToDeliver = _getAmountToDeliver(
                _currentParticipant,
                _box.tokenAmount
            );
        } else {
            _amountToDeliver = _box.tokenAmount;
        }
        _box.tokenAmount -= _amountToDeliver;
        (bool sent, ) = payable(msg.sender).call{value: _amountToDeliver}("");
        require(sent, "Failed to send Ether");
        receiverToBox[msg.sender].push(_boxId);
        _box.participantsPrize.push(_amountToDeliver);
        emit Claimed(true);
    }

    /// @notice Claim your crypto locked in contract
    /// @param _boxId id of box in bytes256
    /** @dev In case it's been more than 24 hours and participants have not claimed all possible crypto,
           the box creator can claim crypto locked in this contract**/
    function creatorWithdraw(bytes memory _boxId) external {
        Box storage _box = box[_boxId];
        require(_box.creationTime + 86400 >= block.timestamp, "Too soon");
        require(_box.tokenAmount > 0, "Empty box");
        require(_box.creator == msg.sender, "Not creator");
        _box.tokenAmount = 0;
        (bool sent, ) = payable(msg.sender).call{value: _box.tokenAmount}("");
        require(sent, "Failed to send Ether");
        emit CreatorWithdrawn(true);
    }

    /********************************************************
     *                                                       *
     *                INTERNAL FUNCTIONS                     *
     *                                                       *
     ********************************************************/

    /// @dev used in claim function
    /// @param _participantsCounter current number of participants for the box
    /// @param _tokenAmount amount of crypto left in the box
    /// @return _amountToDeliver amount of crypto to be deliver to claimer. It is random number between 1 and _tokenAmount
    function _getAmountToDeliver(uint _participantsCounter, uint _tokenAmount)
        internal
        view
        returns (uint _amountToDeliver)
    {
        _amountToDeliver =
            (uint(
                keccak256(
                    abi.encodePacked(_participantsCounter, block.timestamp)
                )
            ) % _tokenAmount) +
            1;
    }

    /********************************************************
     *                                                       *
     *                     GET FUNCTIONS                     *
     *                                                       *
     ********************************************************/

    function getBox(bytes memory _boxId) external view returns (Box memory) {
        return box[_boxId];
    }

    /// @dev used in front-end to display creator box data
    /// @param _creatorAddress address of box creator
    /// @return _box All box created by user
    function getCreatorBox(address _creatorAddress)
        external
        view
        returns (Box[] memory)
    {
        bytes[] memory _creatorToBox = creatorToBox[_creatorAddress];
        Box[] memory _box = new Box[](_creatorToBox.length);

        for (uint i = 0; i < _creatorToBox.length; i++) {
            _box[i] = box[_creatorToBox[i]];
        }
        return _box;
    }

    /// @dev used in front-end to display receiver box data
    /// @param _receiverAddress address of box creator
    /// @return _box All box a user has opened
    function getReceiverBox(address _receiverAddress)
        external
        view
        returns (Box[] memory)
    {
        bytes[] memory _receiverToBox = receiverToBox[_receiverAddress];
        Box[] memory _box = new Box[](_receiverToBox.length);
        for (uint i = 0; i < _receiverToBox.length; i++) {
            _box[i] = box[_receiverToBox[i]];
        }
        return _box;
    }
}