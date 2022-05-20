pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./ERC721Receiver.sol";
import "./NFTornado.sol";

contract NFTornadoCollection is NFTornado, ERC721 {
    bytes4 constant private MAGIC_ON_ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    mapping(uint256 => address) private tornadoApprovals;
    mapping(address => address[]) private operatorApprovalsPerOwner; // Allows multiple operators per owner

    uint mintFee = 0.0001 ether;

    constructor() NFTornado(666) {
    }

    function _isZeroAddress(address _address) internal pure returns (bool) {
        return _address == address(0);
    }

    modifier isNotZeroAddress(address _address) {
        require(!_isZeroAddress(_address), "cannot be the zero address");
        _;
    }

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(tornadoIdToOwner[_tokenId] == msg.sender);
        _;
    }

    modifier isValidToken(uint256 _tokenId) {
        require(_doesTornadoExist(_tokenId), "_token is not a valid NFT");
        _;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(!_isZeroAddress(_owner));
        return ownerTornadoCount[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        address owner = tornadoIdToOwner[_tokenId];
        require(!_isZeroAddress(owner));
        return owner;
    }

    function mintTornado() public validateCorrectAmountOfTornadoes payable {
        require(msg.value >= mintFee, "Insufficient funds sent to mint Tornado");
        uint256 tornadoId = _createPseudoRandomTornado(msg.sender);
        emit Transfer(address(0), msg.sender, tornadoId);
    }

    function approve(address _approved, uint256 _tokenId)
        external
        payable
        isValidToken(_tokenId)
        onlyOwnerOf(_tokenId)
    {
        tornadoApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId)
        external
        view
        isValidToken(_tokenId)
        returns (address)
    {
        return tornadoApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        if (_approved) {
            operatorApprovalsPerOwner[msg.sender].push(_operator);
        } else {
            for (
                uint256 i = 0;
                i < operatorApprovalsPerOwner[msg.sender].length;
                i++
            ) {
                if (operatorApprovalsPerOwner[msg.sender][i] == _operator) {
                    delete operatorApprovalsPerOwner[msg.sender][i];
                    break;
                }
            }
        }
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function _isApprovedForAll(address _owner, address _operator)
        internal
        view
        returns (bool)
    {
        address[] memory operators = operatorApprovalsPerOwner[_owner];
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] == _operator) {
                return true;
            }
        }
        return false;
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {
        return _isApprovedForAll(_owner, _operator);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) private {
        tornadoIdToOwner[_tokenId] = _to;
        ownerTornadoCount[_from]--;
        ownerTornadoCount[_to]++;
        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable isValidToken(_tokenId) isNotZeroAddress(_to) {
        require(
            tornadoIdToOwner[_tokenId] == msg.sender ||
                _isApprovedForAll(_from, msg.sender) ||
                tornadoApprovals[_tokenId] == msg.sender,
            "msg.sender is not the current owner, no authorized operator was found, or no approved address was found"
        );
        _transfer(_from, _to, _tokenId);
    }

    function isContract(address _to) internal view returns(bool){
      uint32 size;
      address a = _to;
      assembly {
        size := extcodesize(a)
      }
      return (size > 0);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external payable isValidToken(_tokenId) isNotZeroAddress(_to) {
        require(
            tornadoIdToOwner[_tokenId] == msg.sender ||
                _isApprovedForAll(_from, msg.sender) ||
                tornadoApprovals[_tokenId] == msg.sender,
            "msg.sender is not the current owner, no authorized operator was found, or no approved address was found"
        );
        _transfer(_from, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721Receiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            );
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable isValidToken(_tokenId) isNotZeroAddress(_to) {
        require(
            tornadoIdToOwner[_tokenId] == msg.sender ||
                _isApprovedForAll(_from, msg.sender) ||
                tornadoApprovals[_tokenId] == msg.sender,
            "msg.sender is not the current owner, no authorized operator was found, or no approved address was found"
        );
        _transfer(_from, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721Receiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                ""
            );
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return
            interfaceId == type(ERC721).interfaceId ||
            interfaceId == type(ERC721Metadata).interfaceId;
    }

}