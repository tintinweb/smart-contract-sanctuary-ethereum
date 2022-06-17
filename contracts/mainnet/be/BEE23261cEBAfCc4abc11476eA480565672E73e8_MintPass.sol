// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// PPGGGGGGGGGGGGGGGGGGGGGPJ~^::..     ...:^^^...:^~:                   ... ..            ..::^~^::^^~!^:::~~~~!7?JJJYJ?YP5YYY?7!~~^^!777!..::^~7???!.             .^~!^..   ..:!J5PPPPGGGGGGP5GGGGGGGGGGGG //
// GGGGBBBBGGGGGGGGGGGGBBG55J?7!!~::::::^^^::.     ...  ........        ..........  .:.    ..:^^^::^^~~~^^~!77??J5Y!~^ .5GPGBP5YY?!!!7???:   ::.^?JY?7~..           .   .  ..:^~~~7YGGGGGGGGGGGGGGBBBBGBBBB //
// GGBBBBBBBBBBGGGGPPP5PGGG5P5YYJ?77!~~~~^^^^:...      .::^!77!!~~^^:....:::.::::::^^.      ..:^^^~~~!7?~^7?7J?7??^..:7P###BB#BBG5J??!!!!^.:!JYJ!?YYYJJ?7!~.               .:.::^^7YP5YPPPGBBGGGGBBBGGBBBGG //
// GBBBBBBBBBBBGGGP5YJ?77?J????JJJ???7!!!~^^^:^:..     .......:^~~!!!!!~^^^::^^:^!?5P?::.     :~!????JJJ?J?:....:^!7JG######BB#BBBGPPP55J?YG5JPPYJY555555?!.                   ...^^^!?YJ5GGGPPGBBGGGGG5JJP //
// GGGGBBBBBBBBGGPYYY5J!^^::.:.:~!!7??7~~~~^^::.      .:.    .::::^^~~!77!^.:::?Y5?7?J7?7:      .:::.:...^Y5YYY5PB###########B###BBBBBBBBB##GYBBGP5PGPJ!:....                      ..^..~5PPPP55GPPGGG5!75B //
// GGGGBBGPPPPPGGGPPPP5YJ~..:.  .:..:!!:..:^^:..    ....    .::^^^~~~~~~^:....~G#GY?YGGGPP57~~.        .^?P############B#########BB#B#B#####BPGPPPG5?~.  ^!7:                       .. :!JYJYPPPPPGGGPPPGBB //
// GGGBBGP5J^.JGBBBGGPP5YJ!.    .     ..  :!~^:.        ..:::::~!~~~!!!~::.  :5BBBBBBB#BB##BBB5!^^::^!JPB##BBBBBBB####BB########BB###########BGP55GGBG5Y7JJ7!~:                        ^~^!:^JY5PGP5?:JGGGP //
// GGGGGPP?: ^5GPGGGGGGPYJ7.   .     ..  .~!!~.    .!77?J?7!!7YPGGPJ!^:.   .~5BBBBBBBBBBBBBBBBBBBBGBBB#BBBBBBBBBBBBBBB#######BB#BBBB####BB##BBBB#BGBBBBGJ?7~7?!^.                      .^:. ..^!7YPP5YPGGPY //
// GGGPJ?^  ~GBGGPPGGGGGPY^  ..    ^~~~!7!!!~^.    :!JPPPGGGBBB##B#BPY?77!7PB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB####################################BBG5YJJ5PYJ?!.                     . ....^^:^^7JJ7?P5YP //
// GP5J!. .!GBBBGGGPGPP5J~.  .. .~JJJ??JJ?77~..:..^!?PGGBBBB########B###############B####BBBBBBBBBBBBBBBBBBBBBBB#####################################B5YYJY555YJ??~:               .     ....:^:^^^^^~?P5PG //
// 57:::.^JGBBBBBGGG5?!??~:::...:!YGGPP5YJJ?7^:::~7YG################################BBBB#####BBBBBBBBBBBBBBBBBBBBB######B###########################PYPGPYY55Y5PP5Y?!^.         .:^..        ....:~YPGGPGB //
// J?J5GPGBBBGGG5??J?7~^!JYYY?!~^~!YPB#BBBG57^^~5BB###################################BBGGP5YJ?!~!7??JY55PPGGBBBBBBBBB###B###########################BGBGBGYY5PPPPPPPYJ7~^:::::^~~~!7!^.       .!?YPPPPP5PG //
// BBBBBBBBBBBBBP7~!~^:::^?GGP5Y7!~~7PBB##B#BBB###################################BG5?7!^:..  ....     ...::^~!?Y5PGB#B#################################PPGGPY?J5PGPP5JJJYYJ7~^:~7JYJJ?:    .  :YPGP55Y5GPP //
// JB#BBBBBBBBBBBP5PPY?!::?GGPGP5J~^~~75#BBB###########################BB#####BG57^. .!^.        ...             ..^~?5GB################################GPP5GP5JJ5PP555YJ?????7~J5YJJ~.    ..  .~?JJ!^?GG5 //
// GBBBBBBBBBBBBBGPP5J55J5GGGGPGGP?!7^^!P##################################BY!~:           ::::. .   .                 .~?PB###############################GY5GPG5YJJ?77??YG##P7!7JJY?^.    ...    ..  :?PP
// BBBBBBBBGGGPYJ??JYPGBBBBBBPBBBG55J7!!!5###########B#######BB#########BGJ^        .    :!J?!~^^^^. ..   .        ..  .  .^?PB################################GG##BBGGPGB###57!?YYJY57:. ....   .~7:  ^J5G
// BBBBBBGP5P5YY5PY~~7YGBBBBBGBBBBBBBP?!~J#################B##########GJ~.      .. .     ^~~^::.:^^. .. .     .    ......:7!..^?P##B############################BB##BBB#####GY?JY555PP7:.        .:!!  :!Y5
// BBBBBGGGBGGGGBGP?^  7BBBBBBBBBBGGP5?!^Y######################B###P7.  . .:.          .     .... .   ..     .        .::^:..  .!5B####################################B#BGJ7?55PGPGG?:.               ^JY
// BBBBBB##BBBBBBG5Y?^ :5BBGBBBBBG5J5Y?!!5############GPGGPGPPB###P!. ...^^......    .:::.    ..              .....   . .::.       ^YB##################################BB#P?!!?5PGGGG5J?~               7Y
// GPGBB##BBBBBBGGGPJ?^.~G#B####BG5Y5Y??5B##########B55GGP5J5YYPG?.  .::?G5^.::^:^^:.::... .               ....:^^:..  ...^:.   .    ^5##################################BBPJJ!7PGGGGGGBG5J?~... :::^^.  !Y
// JYGG5PGBBBBBBG5J?7!::J#######BGGG5JYP###########B5BBPGGPGYP77JJY!^:::^!^:::::::^::......................::.....................~!~:.7B#################################BP5Y?J5PGGGGBGPGBG5?:.^!~:^??^ :7
// JPGGY555PGBGG5YJ?!~~?G#######B5JPGPB###########BPBBG55PGGY5JJ55GJJJJ7!^:^:^~~^^!~:^^^^:::^::::::::::::::::::::::::::~~::::::::!JJJ7^:~P################################BP55JJY5PPGBBBBBBGG?:^!!~!?5GPY!^
// BBBBGPJ5GGGGPPGJ~?JG#########B5JJG#############PBBBPGGJGG?G?5GGB5Y?7?J5J?!~~~!!~^~~^::^^^^:^^^^:::^^^^^^~~~~~^~^^:::!~:::^~~~~7!^^^::.:Y################################G7^~!7?55YJ7YJYGGJ^^!7!?YPGPPGBG
// BB#BGBBBGPBBBB5JP#############BPJP############GGBBGGGP5B5JGJGBB###BBGPG5Y555JJ?!~^^^^^^^^^^^^^^^^^~~~^^~~~~~~^^^^^::^^^^:::^^:^:::::::::5#################B##############BJ^:.:^:..:~:.75!^~?Y?JBBGPY5GG
// B##BB##BBBBB#BB################B5Y############YGBG5BGPBGJ55GBBB#######BBGP55PGGP5?!~~~^^^^^^^^^^^^^^^^^^^^^^^~~~^^^^^~!~^^~~~^:::::::::::P################B################B5?~^^~???7..~~^!?Y?~?PGPPPPG
// P############################BGPPP##########&PYBBG55PBPYP5PGB############BBBBBP55PGJ~!!~^^^^^^^^^^^^^^^^^^~!777!^^^^^^^^^^!!~^^:^^!JYJ7^:~B####################################BBB#BP7..^Y!^~!7?J?5GGBBG
// P########GJ5###############BGPPY5B##########&YPBBBBGBPYBGBBGB#################BB5Y557?YP5!^^^!~^^~~^~~~7?5PGPGGPJ!~~^^^^^~~^^:^!Y555JJY7::J######################################B##B~..:?5?!~~~7???JJ?J
// B########BJ7P#############BPYJYYP############GB#BBBGPPBGB######################BPGG55?7JJ~~7?7!!~~~!7~?5GG5?!!!777~^^^^^^^^:::^5P7!P57^!!:^B####################################BBBB#5:..:75P57~777Y555P
// #########B5!J#######BP5YGGP5??PB###############BBGPPBBGB####################BPPB#BBG55PJ?7!??JJ?7!!?5PBGP5J?7777!^^^^^::^::::::?57~!!7^^~::JB##################################BBGG###5^   ~J7~!5BGGPY?J
// B#######G?~~5#B#####PYYPGGP55G#################BBGBBB##&####################G?YP#BB#GY?7?YJ!!??!~!7JBBPYJ?777!!!7!!::^::::::...:~!~^:.....:~B####################################BGGGB#G?^.     .^7555??
// ######G7^^7PBGG##BP?!GBP5YYP######################B5Y5PGG###########################BY!!~^~~^^::^^^?PP55PPPGBBG5J?~:::^~^~~~^::....... ::^^~#################################GB###BGPPG##BPJ?7^~: :G#BBB
// ######P^~P##BGGBPPGY5B##BB########################&J:^^!Y##BBBB##################GYJ?7!~^^^:::::::^:7JPGPP5PGBBBG57~^:^~75P5Y!:..... ...~~:~B###########################B###GG#######BB#######JP5!!5BBBB
// ##BBBB57G#####B?~5#################################J^!5PB##GB#BGBBGG############P~!!!!~^:^^:::::::^::~~!?YPBBGPY??!:^:~^!?~^~~~?7:....:^~^:7B##################################GPPPB#########P~JBB~.?BBB
// BPJJJYPB######5~J##################################?:7G###55GBGBPJ55B###########P!~^^^^^::::^:::::^^^:^^^~!7?77!~^^:^::^~:.:::~7J!!??7JJ!^~?B#################################B5YYP##########B?~5GY5PPBB
// BGPGBB####BBBGJYG##################################J^^5##G??GG5?77PPB###B5GBB5YY777??777??^:::::^^^^~^~~^:.:::::::::^:..^^^^::^:!J?YY7~^^^~J###################################GGGPB#####BGPPJ~?BG5PG5GG
// ########GJ?YP5J7JB#################################P~~?5G5?77?!!7?5PB#BGP5GBGY7???J?77?7!?~^^^~~~^~?7::~7~^::::::::....:^^~^:.:^J5555YY!:^^5##################################BB#BBG#B55J?YPPY!Y#G5PP5GB
// ######BBG??PGPPPG###################################!^^~!~!~^~7?JJ5P5577?Y55PPY?!~~!~~^^!!~J57!7J5PBBPJJY5J~:^^^^::::^^^^^:^::^!5?7~^~~~^~?B######################################BBG~.!75PGGGPG#5!7755P
// B###################################################?^!~^!777?PG#55J!7!?7J5PPY?7!!?!~~!7~^7YJ7J5YP5Y55Y7!?5PJ~~~~^^^^^::^::::^~7YJ7^^^^:!7P######################################BB#7 :7!J5PGGGP7^:::::7
// ##########P5GPPBB###################################B~~~?JJPBGPJJJJ7?Y?77YYY7!77!77?J7!!^^^^^~77!!~^~!~^~^^?P57~~^:^~~~!~~~~::^^^!!~^^^!7Y##########################################J  ^?77PPPY: ..^~?Y5
// ####BBB###GYJ?JY?7YB#################################5^:::!PBPJJPJJJJ?7!!JY7!~~!!!!J!!~^^^^^~!!!~~!!77~~^^~^~7J?!:^^^^^~^^^^~~~^:.:^^^!7?B##########################################B7. .^7PP5^...!7J5?7
// BBBBBB##GP5YYJ5PP?Y###################################?^!!~7JJY55J7~~7!!7?77~^:^^~7^^^:::~^?BBBBGGBBBBBGG5?!^^~!^.^:...^!~^^!?~^::77!!??P############################################GY7^ .^7!.. ^PP?!75
// GBBBBBBBBG5JJJJP#BGB##################################B7:^.::^^^^^~^^~~^^^^^:^^^^~^:^^^~JG7?BPGGPP55PPGGBBBGGYJ7:......:^:::^^^^~!7~^7!?#########################################BP7~::PB7   .. .~YP!7YP
// GGGGGGGBBBGGPP5YP##P5G#################################B?~~~~!7~^~?J7~:^^^::::^~~~:7Y5G55Y?YPJ?JY5PPGGGGGGGBP!^^:.....:!^::~!~^:::::~~7B#######################################BB57~?J7J?.      .^?J?7YP
// BBBBBB#####BBBBPY5G?:!5GB################################P5PPP5JP57??J~::^~~:::^^^^^~7J??J?YPPP5PGGGGBBBB5JJJ!^::::.:^:.::~?7!:.:^~!7Y#########################################BB?:^:. ~~      ..^?5P55P
// GGBBBBBBBBBGPPGGPY5P7^^?B#################################P7~!!7?77?J557^:^:~!~^::^^~7!!!7YYJYJJY55GGPPPY7!7?~^^::.:~!~~~^~~^::!Y5YJP#########################################Y~!.  :^.7^      ~Y5PPGBGG
// GGGGBBBBBGGGGPPGG5J7!!!5B##################################G?!^~^^^7~~!J5?^:^^..:^:^!!7?!~~~~^^^^~~~~~!!^^^^.......!JYJ??J~.:^JY?YP###########################################Y .  :PGJY!     .^JGGGGGBB
// PGGGGGGBBBBGGPPPGPPY!75B#####################################P!:.::.^^^^7~:. .:^:...:.:::^~!!~~~?7~~::::... ....: 7?^^^7?!^^~??JPB############################################BJ7: ~BBPPP^     .?GGGGBBB
// PGBGGGGPPPPPGGGGGBBGGGBBBGPB##################################BY!:.....::...:..::~~:::^^:~?!~!7Y555YJ?~:.:^::.:.  ~!~!!7~::!JPP################################################B?^ .5GJ5G5: .  ~BBBBBBBB
// :~7?YYJ7J55PPP5Y555P5555Y?!?PB###################################G?^:...::..^~^^::!!~~~~!?7:^77JY?7!^^~!7^~~^^.:7Y7~!!7!^!?YG############################################BBBBB##G~  :JPPPG! ..:JGBBGBBBG
//     ...~JY5PPPPPPP5Y??J?7J5^.^!YB##################################B57^.:~^^!~^7^^:.:..^:!?7!:. .:..:~^:.....^:JPP555YY7JBB###################################B#######BP55PPPPGBB~   :555G~  :?J5GBBBP?!
//       ..^~!?JYYY??JJYJ??!~~~..^.^P#BBBBBBBBB##########################GY!:..~JJJJPY7!~~~~:  ..::~^^...^^..: :!JPPG5J5P5B#################################B##BB###B##P7:... . :JGGJ.  .?5PJ  .~!5GGGGP7:.
//   .       ...:?JJYYJJ?77!!~^..:!^~5B#BB#BB#########B#####################BPJ!!~^!~~~~~^^:^!. ~!~~^^~7JJ7!7JYPBBBBPPB##############################################B?:    :7Y?75GBY  ^JY?7^  .?!J5PP?: .:
//  ...          ^JYJJ?777~^~!~:..75!~JB###########B##GB########################BGPY?!!~!?YJ?7~?5YYJ?J5Y5G5PGBBB#B###################################################J      .???GPGP: !5YJ??J!. :. .!G! . .
//               .~7!77!!!~~77!^:^5BY!JB##################################################BGGGGBGGP55PGGB############################################################7    ....:JGGBP^?JJYYJ555!.   .7J^~!!?
//                .~^^!!!~!!77~:::!5BBB##############################################################################################################################P!.   .  Y#BBBB5YYP5YJ?!~::.  .. ^~!?Y
// ..             .~~:^~^~!7?J7!~^~?P###B#############################################################################################################################5     . ~BBBP5555?~..        ::~!~!??
//  .             .7???77!???JJY55555PBBPG########################################################################BB#################################################BB7    ...YBGY??7:   ..  :^:~J5Y?!?5P5
// ..             :^^~~7~.^7?JJYPGPJ?7JGGG##########################################################################################################################BG##?.   . !GJ??7^      .~JP5PGGGPPGGPP
// ^                  ..::^7?77Y5Y?!!!JB###############################BG##########################################################################################BB##BB57!^  7P?!!~^   ..^7YGGGPPGGPBBBGP
// ^                    .^7!^::!?7~^^JBBB###############################BBB##############################################################################GG########GG##B5BBP~  7G57~^^  ^?!~^^!7?JPPPGGGGGG
// :                     ...   .....!GBGB###################################BB#############################################################B###########BBBBBBBGGPGBG#GJ~:^^^^. 7PJ~^^~^:::       ^J5GGGPPPP
//                                 .JBBBBBB##BBB###########################B################B#########################B###############################BBBBBBBBBBPGBP?:   .?5~:JP7!~^~!~.    .:~~^^?PPGPPP55
// .                          .:.  .JBBBBBB###BB############################################B############################################################B#####BB#Y.     ?BY~YBP?7!~^.     .7JJJJ??55P5555Y
// .                           ~Y7:^YBBBBB####################################################################################################################GYJ5:     :GBGPPP5JJ7~^.    .^!!~^^~~J??Y555P
//                              !PYJPBBBB##GPGBGBB###5YGG##################################################################################################BGGBGPP?.   .J5JJ??777~~77:    .:. .:.^!????JGGG
//                              .?PGBBBB###BGGG5Y5GPPGB5~?B#########################################################################################B#####BG5GBBBBB^  :^~^....::^.^?J!    .:::^??~?55555GGG
//                      ..       ^??JPB##B57~~~~^::::^5BJ7PBB###################################################################################B###B####BG5JG#BGY?~  .:^....::^^:!!^:    .!Y?7??JPGGPGGGGG
//                   . ..       ^7!~?PBBB7....::......:!~::^^!7JG#B5G####################################################################BBB####BBBB####BGPYYBP!.     ......::.....        :?555YPGGPPPPGGG
//  ..               ..^!.      ^YYJY55PGJ!^::::~~~^:^:...   ...^5BY~JB####################################################BBBB#######B#BBBBBBB##BBBBBBBBBBBB!. .^:::^^......               ^JJ55GGPGGPGGGG
//                    ..^:       ^!!~!JPGGY?7~~7??7!!~^:..      .!BB?^P#BGPGBB######################################BB########BBBBB##BBBBBBBBG5JJ?7?J5GGGGGG!  .JYJ!^^:.                   .:^^~YGGGGGGGGGG
//                        .         ..^7J7~~^~!7777!?!^^^:.     .^!?J!J5J7?YJPB###########################B#####BBBBBBBBBBBBGGGGBBBBBBBBBBBGJ~.     .:~!7!7?.  .!!!^..                     ..:^!5GGGGGGGGGG
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * @title Token contract for the Nifty Mint Pass
 * @author maikir
 * @author lightninglu10
 *
 */
contract MintPass is ERC1155Supply, Ownable {
  event PermanentURI(string _value, uint256 indexed _id);
  string public constant name = "I'm New Here Mint Pass";
  string public constant symbol = "INHMP";

  using Address for address;
  uint256 public totalTokens = 0;
  mapping(uint256 => string) private tokenURIS;
  mapping(uint256 => uint256) private tokenPrices;
  mapping(uint256 => bool) private tokenIsFrozen;
  mapping(address => bool) private admins;

  // Sale toggle
  bool public isSaleActive = false;

  event Donation(address indexed _sender, uint256 _value);

  constructor(uint256[] memory _tokenPrices, string[] memory _tokenURIs)
    ERC1155("")
  {
    require(
      _tokenPrices.length == _tokenURIs.length,
      "Token prices array size and token uris array size do not match"
    );

    for (uint256 i = 0; i < _tokenURIs.length; i++) {
      addToken(_tokenURIs[i], _tokenPrices[i]);
    }
  }

  modifier onlyAdmin() {
    require(owner() == msg.sender || admins[msg.sender], "No Access");
    _;
  }

  /**
   * @dev Allows to enable minting of sale and create sale period.
   */
  function flipSaleState() external onlyAdmin {
    isSaleActive = !isSaleActive;
  }

  function mintBatch(
    address to,
    uint256[] calldata ids,
    uint256[] calldata amount
  ) external onlyAdmin {
    _mintBatch(to, ids, amount, "");
  }

  function setAdmin(address _addr, bool _status) external onlyOwner {
    admins[_addr] = _status;
  }

  function addToken(string memory _uri, uint256 _ethPrice) public onlyAdmin {
    totalTokens += 1;
    tokenURIS[totalTokens] = _uri;
    tokenPrices[totalTokens] = _ethPrice;
    tokenIsFrozen[totalTokens] = false;
  }

  function updateTokenData(uint256 id, string memory _uri)
    external
    onlyAdmin
    tokenExists(id)
  {
    require(tokenIsFrozen[id] == false, "This can no longer be updated");
    tokenURIS[id] = _uri;
  }

  function freezeTokenData(uint256 id) external onlyAdmin tokenExists(id) {
    tokenIsFrozen[id] = true;
    emit PermanentURI(tokenURIS[id], id);
  }

  function mintTo(
    address account,
    uint256 id,
    uint256 qty
  ) external payable tokenExists(id) {
    require(isSaleActive, "Sale is not active");

    require(
      msg.value >= (tokenPrices[id] * qty),
      "Ether value sent is incorrect"
    );

    _mint(account, id, qty, "");
  }

  function mintToMany(
    address[] calldata to,
    uint256 id,
    uint256 qty
  ) external payable tokenExists(id) {
    require(isSaleActive, "Sale is not active");

    require(
      msg.value >= (tokenPrices[id] * qty * to.length),
      "Ether value sent is incorrect"
    );

    for (uint256 i = 0; i < to.length; i++) {
      _mint(to[i], id, qty, "");
    }
  }

  function donateFunds() external payable {
    require(isSaleActive, "Sale is not active");

    emit Donation(msg.sender, msg.value);
  }

  function uri(uint256 id)
    public
    view
    virtual
    override
    tokenExists(id)
    returns (string memory)
  {
    return tokenURIS[id];
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return uri(tokenId);
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  modifier tokenExists(uint256 id) {
    require(id > 0 && id <= totalTokens, "Token Unexists");
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}