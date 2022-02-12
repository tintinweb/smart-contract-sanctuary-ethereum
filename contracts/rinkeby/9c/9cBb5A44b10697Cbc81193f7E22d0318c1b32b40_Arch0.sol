//SPDX-License-Identifier: MIT
  pragma solidity ^ 0.8.7;

  import "@openzeppelin/contracts/access/Ownable.sol";
  import "@openzeppelin/contracts/utils/Strings.sol";
  import "@openzeppelin/contracts/utils/Context.sol";
  import "@openzeppelin/contracts/utils/Address.sol";

  contract Arch0 is Ownable {

    using Address for address;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.Set;

    mapping(address => EnumerableSet.Set) internal TokensByOwner;

    /// @notice A descriptive name for a collection of NFTs in this contract
    string constant public name = "Arch0";

    /// @notice An abbreviated name for NFTs in this contract
    string constant public symbol = "ARCH0";

    /// @notice Count NFTs tracked by this contract
    uint256 constant public totalSupply = 10000;

    address constant CHAR0 = 0x7562f9BDe5D32687B599a0BD98bAc28dBa4bC9cD;

    address constant pointersObjectsAddress = 0x014101c5b6456cAF695a9aaa539594e489357CD9;
    address constant ownersIndexAddress = 0xc7E4821026aE80ffAb31a1Ad15E5Bca65b5493c1;
    address constant tokenArrayAddress = 0x2210b9AEC7a5906F95B1aF3c43FC5e302156AF0e;
    address[8] ownersBucketsContracts;

        string public baseURI;
        bool public initTransfersComplete;

        // Mapping from token ID to owner address
        mapping(uint256 => address) private _owners;

        mapping(address => uint16) private _numDropsSoldbyAddress;
        mapping(uint256 => bool) private _dropSold;

        // Mapping from token ID to approved address
        mapping(uint256 => address) private _tokenApprovals;

        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) private _operatorApprovals;

        mapping(uint256 => string[6]) skillOptions;
        mapping(uint256 => string[6]) featOptions;

        uint256 constant CLASS_CHANCE = 12;

        string[6] races = [
          'Human',
          'Halfling',
          'Dwarf',
          'Elf',
          'Half-Orc',
          'Half-Elf'
        ];
        string[6] classes = [
          'Rogue',
          'Knight',
          'Magician',
          'Healer',
          'Jester',
          'Fighter'
        ];

        constructor() {

        ownersBucketsContracts = [
          0x97B3A324332910304e6Db1e8743869604f86027f,
          0x8163725fC897AF7812D98a03E4033A54F16B6520,
          0x6BD5799EDf8D55c0ab55a11F3f06dDB7D192C4E9,
          0x06a24F09C17677584B45d20FeB0eADc93ACf9699,
          0xF86c21D8Cc5F7f5C1B570431Ea05c5464BBe5Dd4,
          0x8E48bAEE0D764ba51a67697d32078C99d45BD7d6,
          0x77D82CE20a69273a8614B6cF15b86E44d393e96d,
          0x8B8fEad03Fb90C39253C3AA5f7C119Cc57848eAE
        ];

          skillOptions[0] = [ //Rogue
            'Hide',
            'Open Locks',
            'Find Traps',
            'Stealth',
            'Climb',
            'Senses'
          ];
          skillOptions[1] = [ //Knight
            'Diplomacy',
            'Stabilize Self',
            'Intimidate',
            'Climb',
            'Senses',
            'Stealth'
          ];
          skillOptions[2] = [ //Magician
            'Concentration',
            'Diplomacy',
            'Stabilize Self',
            'Intimidate',
            'Senses',
            'Write'
          ];
          skillOptions[3] = [ //Healer
            'Treat Wound',
            'Concentration',
            'Ancient Languages',
            'Diplomacy',
            'Senses',
            'Write'
          ];
          skillOptions[4] = [ //Jester
            'Diplomacy',
            'Bluff',
            'Write',
            'Stealth',
            'Senses',
            'Concentration'
          ];
          skillOptions[5] = [ //Fighter
            'Climb',
            'Intimidate',
            'Bluff',
            'Senses',
            'Stealth',
            'Stabilize Self'
          ];
          featOptions[0] = [ // Rogue
            'Sneak Attack',
            'Disable Trap',
            'Run',
            'Weapons Expert',
            'Point-Blank Shot',
            'Dodge'
          ];
          featOptions[1] = [ // Knight
            'Weapons Expert',
            'Toughness',
            'Bash',
            'Run',
            'Taunt',
            'Bull Rush'
          ];
          featOptions[2] = [ // Magician
            'Maximize Spell',
            'Silent Spell',
            'Double Spell',
            'Use Device',
            'Confuse',
            'Dodge'
          ];
          featOptions[3] = [ // Healer
            'Prayer',
            'Ward Undead/Demons',
            'Maximize Spell',
            'Silent Spell',
            'Double Spell',
            'Toughness'
          ];
          featOptions[4] = [ // Jester
            'Confuse',
            'Use Device',
            'Taunt',
            'Dodge',
            'Toughness',
            'Double Spell'
          ];
          featOptions[5] = [ //Fighter
            'Weapons Expert',
            'Bull Rush',
            'Bash',
            'Run',
            'Toughness',
            'Taunt'
          ];
        }

          /// @dev This emits when ownership of any NFT changes by any mechanism.
          ///  This event emits when NFTs are created (`from` == 0) and destroyed
          ///  (`to` == 0). Exception: during contract creation, any number of NFTs
          ///  may be created and assigned without emitting Transfer. At the time of
          ///  any transfer, the approved address for that NFT (if any) is reset to none.
          event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

          /// @dev This emits when the approved address for an NFT is changed or
          ///  reaffirmed. The zero address indicates there is no approved address.
          ///  When a Transfer event emits, this also indicates that the approved
          ///  address for that NFT (if any) is reset to none.
          event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

          /// @dev This emits when an operator is enabled or disabled for an owner.
          ///  The operator can manage all NFTs of the owner.
          event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

          event BaseURISet(string baseURI);

          /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
          /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
          ///  3986. The URI may point to a JSON file that conforms to the "ERC721
          ///  Metadata JSON Schema".
          function tokenURI(uint256 _tokenId) public view returns(string memory) {
            require(_tokenId > 0 && _tokenId < 10001, "ERC721Metadata: URI query for nonexistent token");
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
          }


          function tokenData(uint256 _tokenId) public view returns(string memory) {
            uint256 race = getRace(_tokenId);
            uint256 class = getClass(_tokenId, race);
            string memory alignment = getAlignment(_tokenId, class);
            uint256[3] memory skills = getSkills(_tokenId);
            uint256[3] memory feats = getFeats(_tokenId);
            return string(abi.encodePacked(
              '{"race":"', races[race],
              '","class":"', classes[class],
              '","alignment":"', alignment,
              '","skills":["',
              skillOptions[class][skills[0]], '","',
              skillOptions[class][skills[1]], '","',
              skillOptions[class][skills[2]], '"],"feats":["',
              featOptions[class][feats[0]], '","',
              featOptions[class][feats[1]], '","',
              featOptions[class][feats[2]], '"]}'
              ));
            }

          /// @notice Count all NFTs assigned to an owner
          /// @dev NFTs assigned to the zero address are considered invalid, and this
          ///  function throws for queries about the zero address.
          /// @param _owner An address for whom to query the balance
          /// @return The number of NFTs owned by `_owner`, possibly zero
          function balanceOf(address _owner) public view returns(uint256) {
            require(_owner != address(0), "ERC721: balance query for the zero address");
            return uint256(TokensByOwner[_owner].length() + getSSBalanceOf(_owner) - uint256(_numDropsSoldbyAddress[_owner]));
          }

          /// @notice Find the owner of an NFT
          /// @dev NFTs assigned to zero address are considered invalid, and queries
          ///  about them do throw.
          /// @param _tokenId The identifier for an NFT
          /// @return The address of the owner of the NFT
          function ownerOf(uint256 _tokenId) public view returns(address) {
            address owner = _owners[_tokenId] != address(0) ? _owners[_tokenId] : address(bytes20(getSSOwnerOf(uint16(_tokenId))));
            require(_tokenId <= 10000 && _tokenId > 0, "ERC721: owner query for nonexistent token");
            return owner;
          }

          function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns(uint256 tokenId){
            require(_index < balanceOf(_owner), "ERC721Enumerable: owner index out of bounds");
            tokenId = uint16(getSSTokenOfOwnerByIndex(_owner,_index));
            if(tokenId != 0) {
              return tokenId;
            }
            return TokensByOwner[_owner].at(_index - (getSSBalanceOf(_owner) - _numDropsSoldbyAddress[_owner]));
          }


        /// @notice Transfers the ownership of an NFT from one address to another address
        /// @dev Throws unless `msg.sender` is the current owner, an authorized
        ///  operator, or the approved address for this NFT. Throws if `_from` is
        ///  not the current owner. Throws if `_to` is the zero address. Throws if
        ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
        ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
        ///  `onERC721Received` on `_to` and throws if the return value is not
        ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
        /// @param _from The current owner of the NFT
        /// @param _to The new owner
        /// @param _tokenId The NFT to transfer
        /// @param _data Additional data with no specified format, sent in call to `_to`
        function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable {
          require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
          _safeTransfer(_from, _to, _tokenId, _data);
        }

        /// @notice Transfers the ownership of an NFT from one address to another address
        /// @dev This works identically to the other function with an extra data parameter,
        ///  except this function just sets data to "".
        /// @param _from The current owner of the NFT
        /// @param _to The new owner
        /// @param _tokenId The NFT to transfer
        function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
          safeTransferFrom(_from, _to, _tokenId, "");
        }

        /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
        ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
        ///  THEY MAY BE PERMANENTLY LOST
        /// @dev Throws unless `msg.sender` is the current owner, an authorized
        ///  operator, or the approved address for this NFT. Throws if `_from` is
        ///  not the current owner. Throws if `_to` is the zero address. Throws if
        ///  `_tokenId` is not a valid NFT.
        /// @param _from The current owner of the NFT
        /// @param _to The new owner
        /// @param _tokenId The NFT to transfer
        function transferFrom(
          address _from,
          address _to,
          uint256 _tokenId
          ) public payable {
            //solhint-disable-next-line max-line-length
            require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
            _transfer(_from, _to, _tokenId);
          }

          /// @notice Change or reaffirm the approved address for an NFT
          /// @dev The zero address indicates there is no approved address.
          ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
          ///  operator of the current owner.
          /// @param _approved The new approved NFT controller
          /// @param _tokenId The NFT to approve
          function approve(address _approved, uint256 _tokenId) public payable {
            address owner = ownerOf(_tokenId);
            require(_approved != owner, "ERC721: approval to current owner");
            require(
              _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
              "ERC721: approve caller is not owner nor approved for all"
              );
              _approve(_approved, _tokenId);
            }

            function _approve(address to, uint256 _tokenId) internal virtual {
              _tokenApprovals[_tokenId] = to;
              emit Approval(ownerOf(_tokenId), to, _tokenId);
            }
            /// @notice Enable or disable approval for a third party ("operator") to manage
            ///  all of `msg.sender`'s assets
            /// @dev Emits the ApprovalForAll event. The contract MUST allow
            ///  multiple operators per owner.
            /// @param _operator Address to add to the set of authorized operators
            /// @param _approved True if the operator is approved, false to revoke approval
            function setApprovalForAll(address _operator, bool _approved) public {
              require(_operator != _msgSender(), "ERC721: approve to caller");
              _operatorApprovals[_msgSender()][_operator] = _approved;
              emit ApprovalForAll(_msgSender(), _operator, _approved);
            }
            /// @notice Get the approved address for a single NFT
            /// @dev Throws if `_tokenId` is not a valid NFT.
            /// @param _tokenId The NFT to find the approved address for
            /// @return The approved address for this NFT, or the zero address if there is none
            function getApproved(uint256 _tokenId) public view returns(address) {
              require(ownerOf(_tokenId) != address(0), "ERC721: approved query for nonexistent token");
              return _tokenApprovals[_tokenId];
            }

            /// @notice Query if an address is an authorized operator for another address
            /// @param _owner The address that owns the NFTs
            /// @param _operator The address that acts on behalf of the owner
            /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
            function isApprovedForAll(address _owner, address _operator) public view returns(bool) {
              return _operatorApprovals[_owner][_operator];
            }

          function setBaseURI(string memory _newbaseURI) public onlyOwner() {
            baseURI = _newbaseURI;
            emit BaseURISet(_newbaseURI);
          }
          function getRace(uint256 _tokenId) private view returns(uint256 race) {
            uint256 fateRoll = iChar0(CHAR0).getStat(_tokenId, 6);
            return
            fateRoll <= 40 ?
              0 : //human
              fateRoll <= 60 ?
              1 : //halfing
              fateRoll <= 80 ?
              2 : //dwarf
              fateRoll <= 90 ?
              3 : //elf
              fateRoll <= 96 ?
              4 : //half-orc
              5; //half-elf
          }

          function getClassChances(uint256 _tokenId, uint256 _race) private view returns(uint256[6] memory classChance) {
            uint256 stat = iChar0(CHAR0).getStat(_tokenId, 0);
            stat = //str
              _race == 1 ?
              stat - 2 :
              _race == 4 ?
              stat + 2 :
              stat;

            uint256 strMod = stat >= 13 ?
              stat - 12 :
              0;

            for (uint8 i = 1; i < 6; i++) {
              stat = iChar0(CHAR0).getStat(_tokenId, i);
              if ((i == 1 && (_race == 1 || _race == 3)) || (i == 2 && _race == 2) || (i == 5 && _race == 5)) {
                stat = stat + 2;
              } else if (i == 3 && _race == 4) {
                stat = stat - 2;
              }
              strMod = i > 2 ? strMod * 2 : i == 1 ? strMod : 0;
              classChance[i] = stat >= 13 ?
                (stat - 12) * CLASS_CHANCE - strMod >= CLASS_CHANCE // increase chance for knight
                ?
                classChance[i - 1] + (stat - (i == 2 && _race == 0 ? 12 : 12)) * CLASS_CHANCE - strMod //maybe reduce
                :
                classChance[i - 1] + CLASS_CHANCE :
                classChance[i - 1];
            }
            return classChance;
          }

          function getClass(uint256 _tokenId, uint256 _race) private view returns(uint256 class) {
            uint256[6] memory classChance = getClassChances(_tokenId, _race);
            uint256 fateRoll = iChar0(CHAR0).getStat(_tokenId, 7);
            return
            fateRoll <= classChance[1] ?
              0 : //Rogue
              fateRoll <= classChance[2] ?
              1 : //Knight
              fateRoll <= classChance[3] ?
              2 : //Magician
              fateRoll <= classChance[4] ?
              3 : //Healer
              fateRoll <= classChance[5] ?
              4 : //Jester
              5; //Fighter
          }

          function getAlignment(uint256 _tokenId, uint256 _class) private view returns(string memory alignment) {
            uint256 fateRoll = iChar0(CHAR0).getStat(_tokenId, 8);
            string memory axisA =
              fateRoll <= 30 ?
              (_class == 0 || _class == 4 ? 'Chaotic' : 'Lawful') :
              fateRoll <= 80 ?
              'Neutral' :
              (_class != 3 ? 'Chaotic' : 'Lawful');

            fateRoll = iChar0(CHAR0).getStat(_tokenId, 9);
            string memory axisB =
              fateRoll <= 50 ?
              'Good' :
              fateRoll <= 90 ?
              'Neutral' :
              'Evil';
            return
            keccak256(abi.encodePacked(axisA)) == keccak256(abi.encodePacked(axisB)) ? 'True Neutral' : string(abi.encodePacked(axisA, ' ', axisB));
          }

          function getSkills(uint256 _tokenId) private view returns(uint256[3] memory skills) {
            uint256 fateRoll = iChar0(CHAR0).getStat(_tokenId, 10);
            skills[0] =
              fateRoll <= 30 ? 0 : // skill 1
              fateRoll <= 50 ? 1 : //
              fateRoll <= 65 ? 2 : //
              fateRoll <= 80 ? 3 : //
              fateRoll <= 95 ? 4 : 5; // skill 5/6

            fateRoll = iChar0(CHAR0).getStat(_tokenId, 11);
            skills[1] =
              fateRoll <= 30 ? (skills[0] == 0) ? 1 : 0 : // skill 1
              fateRoll <= 50 ? (skills[0] == 1) ? 2 : 1 : //
              fateRoll <= 65 ? (skills[0] == 2) ? 3 : 2 : //
              fateRoll <= 80 ? (skills[0] == 3) ? 4 : 3 : //
              fateRoll <= 95 ? (skills[0] == 4) ? 5 : 4 : //
              (skills[0] == 5) ? 4 : 5; // skill 5/6

            fateRoll = iChar0(CHAR0).getStat(_tokenId, 12);
            skills[2] =
              fateRoll <= 30 ?
              skills[0] == 0 ? (skills[1] == 1 ? 2 : 1) :
              skills[1] == 0 ? (skills[0] == 1 ? 2 : 1) :
              0 :
              fateRoll <= 50 ?
              skills[0] == 1 ? (skills[1] == 2 ? 3 : 2) :
              skills[1] == 1 ? (skills[0] == 2 ? 3 : 2) :
              1 :
              fateRoll <= 65 ?
              skills[0] == 2 ? (skills[1] == 3 ? 4 : 3) :
              skills[1] == 2 ? (skills[0] == 3 ? 4 : 3) :
              2 :
              fateRoll <= 80 ?
              skills[0] == 3 ? (skills[1] == 4 ? 5 : 4) :
              skills[1] == 3 ? (skills[0] == 4 ? 5 : 4) :
              3 :
              fateRoll <= 95 ?
              skills[0] == 4 ? (skills[1] == 5 ? 3 : 5) :
              skills[1] == 4 ? (skills[0] == 5 ? 3 : 5) :
              4 :
              skills[0] == 5 ? (skills[1] == 4 ? 3 : 4) :
              skills[1] == 5 ? (skills[0] == 4 ? 3 : 4) :
              5;
            return skills;
          }

          function getFeats(uint256 _tokenId) private view returns(uint256[3] memory feats) {
            uint256 fateRoll = iChar0(CHAR0).getStat(_tokenId, 13);

            feats[0] =
              fateRoll <= 30 ? 0 : // feat 1
              fateRoll <= 50 ? 1 : //
              fateRoll <= 65 ? 2 : //
              fateRoll <= 80 ? 3 : //
              fateRoll <= 95 ? 4 : 5; // feat 5/6

            fateRoll = iChar0(CHAR0).getStat(_tokenId, 14);
            feats[1] =
              fateRoll <= 30 ? (feats[0] == 0) ? 1 : 0 : // feat 1
              fateRoll <= 50 ? (feats[0] == 1) ? 2 : 1 : //
              fateRoll <= 65 ? (feats[0] == 2) ? 3 : 2 : //
              fateRoll <= 80 ? (feats[0] == 3) ? 4 : 3 : //
              fateRoll <= 95 ? (feats[0] == 4) ? 5 : 4 : //
              (feats[0] == 5) ? 4 : 5; // feat 5/6

            fateRoll = iChar0(CHAR0).getStat(_tokenId, 15);
            feats[2] =
              fateRoll <= 30 ?
              feats[0] == 0 ? (feats[1] == 1 ? 2 : 1) :
              feats[1] == 0 ? (feats[0] == 1 ? 2 : 1) :
              0 :
              fateRoll <= 50 ?
              feats[0] == 1 ? (feats[1] == 2 ? 3 : 2) :
              feats[1] == 1 ? (feats[0] == 2 ? 3 : 2) :
              1 :
              fateRoll <= 65 ?
              feats[0] == 2 ? (feats[1] == 3 ? 4 : 3) :
              feats[1] == 2 ? (feats[0] == 3 ? 4 : 3) :
              2 :
              fateRoll <= 80 ?
              feats[0] == 3 ? (feats[1] == 4 ? 5 : 4) :
              feats[1] == 3 ? (feats[0] == 4 ? 5 : 4) :
              3 :
              fateRoll <= 95 ?
              feats[0] == 4 ? (feats[1] == 5 ? 3 : 5) :
              feats[1] == 4 ? (feats[0] == 5 ? 3 : 5) :
              4 :
              feats[0] == 5 ? (feats[1] == 4 ? 3 : 4) :
              feats[1] == 5 ? (feats[0] == 4 ? 3 : 4) :
              5;
            return feats;
          }

          function _safeTransfer(
            address from,
            address to,
            uint256 tokenId,
            bytes memory _data
          ) internal {
            _transfer(from, to, tokenId);
            require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
          }

          function _transfer(
            address _from,
            address _to,
            uint256 _tokenId
          ) internal {
            require(ownerOf(_tokenId) == _from, "ERC721: transfer of token that is not own");
            require(_to != address(0), "ERC721: transfer to the zero address");
            // Clear approvals from the previous owner
            _approve(address(0), _tokenId);
            TokensByOwner[_to].add(_tokenId);
            _owners[_tokenId] = _to;
            if(!_dropSold[_tokenId]) {
                _dropSold[_tokenId] = true;
                _numDropsSoldbyAddress[_from] = _numDropsSoldbyAddress[_from] + 1;
            } else {
                TokensByOwner[_from].remove(_tokenId);
            }
            emit Transfer(_from, _to, _tokenId);
          }

          function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns(bool) {
            require(_tokenId > 0 && _tokenId < 10001, "ERC721: operator query for nonexistent token");
            address owner = _owners[_tokenId] != address(0) ? _owners[_tokenId] : address(bytes20(getSSOwnerOf(uint16(_tokenId))));
            return (_spender == owner || _tokenApprovals[_tokenId] == _spender || isApprovedForAll(owner, _spender));
          }

          /**
           * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
           * The call is not executed if the target address is not a contract.
           *
           * @param from address representing the previous owner of the given token ID
           * @param to target address that will receive the tokens
           * @param tokenId uint256 ID of the token to be transferred
           * @param _data bytes optional data to send along with the call
           * @return bool whether the call correctly returned the expected magic value
           */
          function _checkOnERC721Received(
            address from,
            address to,
            uint256 tokenId,
            bytes memory _data
          ) private returns(bool) {
            if (to.isContract()) {
              try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns(bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
              } catch (bytes memory reason) {
                if (reason.length == 0) {
                  revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                  assembly {
                    revert(add(32, reason), mload(reason))
                  }
                }
              }
            } else {
              return true;
            }
          }

          function getSSBalanceOf(address _owner) private view returns(uint256 ssBalance) {
            (uint16 start,uint8 size) = getStartAndSizeOfBucket(uint8(uint160(_owner))); // binned on last byte
            address addr = ownersBucketsContracts[uint8(uint160(_owner))/32];
            for (uint8 i = 0; i < size; i++) {
              (address lookupOwner, uint256 lookupBalance) = getSSBalanceOfOwnerByIndex(addr, start, i);
              if (lookupOwner == _owner) return lookupBalance;
            }
            return 0;
          }

          function getStartAndSizeOfBucket(uint256 _bucketNumber) private view returns(uint16 start, uint8 size) {
            bytes32 bucketPointer;
            assembly {
              bucketPointer:= mload(0x40)
              mstore(0x40, add(bucketPointer, and(add(0x28, 0x1f), not(0x1f))))
              mstore(bucketPointer, 0x20)
              extcodecopy(pointersObjectsAddress, add(bucketPointer, 0x20), mul(_bucketNumber, 0x04), 0x04)
              start:= mload(add(bucketPointer, 0x02))
              size:= mload(add(bucketPointer, 0x04))
            }
          }

          function getSSTokenOfOwnerByIndex(address _owner, uint256 _index) private view returns(uint256 tokenId){
            uint8 bucket = uint8(uint160(_owner));
            address addr = ownersBucketsContracts[bucket/32];
            (uint16 start, uint8 size) = getStartAndSizeOfBucket(bucket); // binned on last byte

            for (uint8 i = 0; i < size; i++) {
              (address lookupOwner, uint16 _tokensStart) = getSSOwnerTokenStart(addr, start, i);
              if (lookupOwner == _owner) {
                return skipSoldDrops(_tokensStart, _index, _owner);
              }
            }
            return 0;
          }

          function skipSoldDrops(uint256 _tokensStart, uint256 _index, address _owner) private view returns(uint256 tokenId){
                  tokenId = getSSTokenByStartAndIndex(uint16(_tokensStart), uint16(_index));
                  if(_index < getSSBalanceOf(_owner)) {
                      if(_dropSold[tokenId]) {
                          return skipSoldDrops(_tokensStart, _index + 1, _owner);
                      }
                      return tokenId;
                  } else {
                      return 0;
                  }
          }



            function getSSBalanceOfOwnerByIndex(address _addr, uint256 _start, uint8 _index) private view returns(address owner, uint16 ssBalance) {
              bytes32 bucket;
              assembly {
                bucket:= mload(0x40)
                mstore(0x40, add(bucket, and(add(0x28, 0x1f), not(0x1f))))
                mstore(bucket, 0x20)
                extcodecopy(_addr,
                            add(bucket, 0x20),  //to
                            add(                //from
                                mul(_index, 0x18),
                                mul(_start, 0x18)
                            ),
                            0x16                //size
                )
                owner:= mload(add(bucket, 0x14))
                ssBalance:= mload(add(bucket, 0x16))
              }
            }

            function getSSOwnerTokenStart(address _addr, uint256 _start, uint8 _index) private view returns(address owner, uint16 _tokensStart) {
              bytes32 bucket;
              assembly {
                bucket:= mload(0x40)
                mstore(0x40, add(bucket, and(add(0x28, 0x1f), not(0x1f))))
                mstore(bucket, 0x20)
                extcodecopy(_addr,
                            add(bucket, 0x20),  //to
                            add(                //from
                                mul(_index, 0x18),
                                mul(_start, 0x18)
                            ),
                            0x18                //size
                )
                owner:= mload(add(bucket, 0x14))
                _tokensStart:= mload(add(bucket, 0x18))
              }
            }

            function getSSTokenByStartAndIndex(uint16 _tokensStart,uint16 _tokenIndex) private view returns(uint16 tokenId){
              assembly {
                tokenId:= mload(0x40)
                mstore(0x40, add(tokenId, and(add(0x28, 0x1f), not(0x1f))))
                mstore(tokenId, 0x20)
                extcodecopy(tokenArrayAddress, //address
                               add(tokenId, 0x20), // to
                                  add(                // from
                                      mul(_tokensStart, 0x02),
                                      mul(_tokenIndex, 0x02)
                                  )
                                  ,0x02    //size
                              )
                tokenId:= mload(add(tokenId, 0x02))
              }
            }

            function getSSOwnerOf(uint16 _tokenId) private view returns(address) {
                _tokenId = _tokenId -1;
                uint16 ownerIndex;
                assembly {
                ownerIndex:= mload(0x40)
                mstore(0x40, add(ownerIndex, and(add(0x28, 0x1f), not(0x1f))))
                mstore(ownerIndex, 0x20)
                // extcodecopy(atAddress,writeTo,readFrom,Size)
                extcodecopy(ownersIndexAddress, add(ownerIndex, 0x20), mul(_tokenId, 0x02), 0x02)
                ownerIndex:= mload(add(ownerIndex,0x02))
                }
                return address(bytes20(getSSOwnerFromIndex(ownerIndex)));
            }


            function getSSOwnerFromIndex(uint256 _index) private view returns(bytes memory owner) {
              uint256 maxIndex;
              uint256 lastMax;
              for(uint8 i = 0; i < 8; i++){
                address addr = ownersBucketsContracts[i];
                lastMax = maxIndex;
                maxIndex = maxIndex + (addr.code.length / 24);
                if(i > 3 && i != 6) maxIndex = maxIndex - 1;
                if(maxIndex > _index){
                  uint256 adjusted_index = _index - lastMax;
                  assembly {
                      owner:= mload(0x40)
                      mstore(0x40, add(owner, and(add(0x28, 0x1f), not(0x1f))))
                      mstore(owner, 0x14)
                      extcodecopy(addr, add(owner, 0x20), mul(adjusted_index, 0x18), 0x14)
                  }
                  return owner;
                }
              }
            }

          function send1000Events(bytes calldata) public onlyOwner initTransfersNotFinalized { //cleanup add confirmations.
            bytes2 start;
            assembly {
              start:= calldataload(0x44)
              for {
                let i:= 0
              }
              lt(i, 1000) {
                i:= add(i, 1)
              } {
                log4(
                  0x00,
                  0x00,
                  0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                  0x00,
                  calldataload(add(mul(0x20, i), 0x64)),
                  add(i, start)
                )
              }
            }
          }

        function finalizeInitTranfers() public onlyOwner {
          initTransfersComplete = true;
        }

        modifier initTransfersNotFinalized() {
          require(!initTransfersComplete);
          _;
        }
      }


      interface IERC721Receiver {
        /**
         * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
         * by `operator` from `from`, this function is called.
         *
         * It must return its Solidity selector to confirm the token transfer.
         * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
         *
         * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
         */
        function onERC721Received(
          address operator,
          address from,
          uint256 tokenId,
          bytes calldata data
        ) external returns(bytes4);
      }

      interface iChar0 {
        function getStat(uint256 _tokenId, uint256 _stat) external view returns(uint256);
      }

      library EnumerableSet {
          struct Set {
              uint256[] _values;
              mapping (uint256 => uint256) _indexes;
          }

          function at(Set storage set, uint256 index) internal view returns (uint256) {
              return set._values[index];
          }

          function contains(Set storage set, uint256 value) internal view returns (bool) {
              return set._indexes[value] != 0;
          }

          function length(Set storage set) internal view returns (uint256) {
              return set._values.length;
          }

          function add(Set storage set, uint256 value) internal returns (bool) {
              if (!contains(set, value)) {
                  set._values.push(value);
                  // The value is stored at length-1, but we add 1 to all indexes
                  // and use 0 as a sentinel value
                  set._indexes[value] = set._values.length;
                  return true;
              } else {
                  return false;
              }
          }

          function remove(Set storage set, uint256 value) internal returns (bool) {
              // We read and store the value's index to prevent multiple reads from the same storage slot
              uint256 valueIndex = set._indexes[value];
              if (valueIndex != 0) { // Equivalent to contains(set, value)
                  // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
                  // the array, and then remove the last element (sometimes called as 'swap and pop').
                  // This modifies the order of the array, as noted in {at}.
                  uint256 toDeleteIndex = valueIndex - 1;
                  uint256 lastIndex = set._values.length - 1;
                  if (lastIndex != toDeleteIndex) {
                      uint256 lastvalue = set._values[lastIndex];
                      // Move the last value to the index where the value to delete is
                      set._values[toDeleteIndex] = lastvalue;
                      // Update the index for the moved value
                      set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
                  }

                  // Delete the slot where the moved value was stored
                  set._values.pop();
                  // Delete the index for the deleted slot
                  delete set._indexes[value];
                  return true;
              } else {
                  return false;
              }
          }
      }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}