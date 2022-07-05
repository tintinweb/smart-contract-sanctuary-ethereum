/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.0;

contract BCRA {

    mapping(address => uint256) private _balance;
    mapping(address => uint256) private _poderDeVoto;

    /// @notice The current Economy Minister
    /// @dev This can be changed or even renounced at any time.
    address public minEconomia;
    
    /// @notice The current "President"
    /// @dev This role is quite pointless. Does not stitches or cuts (no pincha ni corta)
    address public presidente;

    address private _vicepresidente;
    string private _nombre;
    string private _symbol;

    uint256 private _circulante;
    uint256 private _respaldo;

    /// @notice threshold that can be passed in order to pick a new minister
    uint256 public constant PONGO_A_DEDO = 2*(10E18);

    /// @param printer the one who does the brr
    /// @param brrrAmount amount that the maquinola did brr
    /// @param lali current liquidity (lali-quidez)
    event Brrrrr(address indexed printer, uint256 brrrAmount, uint256 lali);

    /// @param from the sender
    /// @param _to the receiver
    /// @dev no amount broadcasted, everything barrani.
    event Transfer(address indexed from, address _to);

    /// @param _new the new puppet
    /// @param _estimatedDuration the estimated duration expectancy of the one in charge
    event NuevoMinistro(address indexed _new, uint256 _estimatedDuration);

    constructor() {
        _nombre = "Wiped Argentinean Pesos";
        _symbol = "WARS"; // Any resemblance with any war is pure coincidence.
        presidente = address(0); // Null
        _vicepresidente = msg.sender; // The bean handles everything (porota maneja todo).
        _respaldo = 100 ** decimales(); // We are kind of ass to the north (culo pa'l norte)
    }

    modifier onlyBrBr () {
        require(msg.sender == minEconomia || msg.sender == _vicepresidente);
        _;
    }

    function nombre() public view virtual returns(string memory){
        return _nombre;
    }

    /// @notice decimales or "say males", so: "Males, males, males..."
    function decimales() public view virtual returns(uint8){
        return 18;
    }

    /// @notice returns the current balance of an Afip victim.
    /// @dev The balance of the victim is adjusted with a magic number that takes into account the non formal cash
    function wardaConLaAfip(address _victima) public view virtual returns(uint256){
        return _balance[_victima] - _balance[_victima] * 20 / 100;
    }

    /// @notice returns the current voting power.
    /// @dev If a threshold is exceeded, the user can pick the new minister
    function cometIndicator(address _ciudadano) public view virtual returns(uint256){
        return _poderDeVoto[_ciudadano];
    }
    
    /// @notice Returns the amount of pesos in the market
    /// @dev Infletta is just a senseishon
    function circulantePesos() public view virtual returns(uint256){
        return (_circulante - _circulante * 20 / 100);
    }

    /// @notice increases the current WARS balance of the _beneficiario
    /// @dev it can overflow, on that case the _respaldo is set as zero
    function maquinolaDoesBrrr(address _beneficiario, uint256 daleNomas) external onlyBrBr {
        if(_circulante + daleNomas < _circulante){
            _respaldo = 0;
        }    
        if(_respaldo == 0) return;  

        _circulante += daleNomas;
        _balance[_beneficiario] += daleNomas;
        emit Brrrrr(msg.sender, daleNomas - daleNomas * 30 / 100, _circulante); // Infletta is just a senseishon we said.
    }

    /// @notice allows users to send and pay with tokens.
    /// @dev contemplates the case of "te fio master".
    function transfer(address _to, uint256 _amount) external {
        require(_to != _vicepresidente || _to != minEconomia, "!cometa");

        uint256 senderBalance = _balance[msg.sender];
        
        // Aka "despues te garpo/me fia master" 
        if(senderBalance < _amount){
            _balance[msg.sender] = 0;
            _balance[_to] += senderBalance;
        } else {

            _balance[msg.sender] = senderBalance - _amount;
            _balance[_to] += _amount;
        }

        emit Transfer(msg.sender, _to); // No amount broadcasted, 100% barrani.
    }

    /// @notice allows users to send perform "Vamo y Vamo" actions.
    /// @param _to either the president or the minister
    /// @param _cometAmount comets to the president or minEconomia
    function vamoYVamo(address _to, uint256 _cometAmount) external returns(uint256 nuevoPoderDeVoto){
        require(_to == _vicepresidente || _to == minEconomia, "This is a cometa, pal");
        
        uint256 senderBalance = _balance[msg.sender];

        require(senderBalance >= _cometAmount);
        _balance[msg.sender] = senderBalance - _cometAmount;
        _balance[_to] += _cometAmount;  

        _poderDeVoto[msg.sender] += _cometAmount * 2;
        nuevoPoderDeVoto = _poderDeVoto[msg.sender];
    }

    /// @notice makes the current minister to renounce
    /// @dev allows both the minister to renounce or to be renounced...
    function renounceMinistry() external returns(string memory){
        require(msg.sender == minEconomia || msg.sender == _vicepresidente, "!porota or !minEconomia");
        delete minEconomia;
        return "Let the hunger games begin";
    }

    /// @notice sets a new minister
    /// @dev because the old minister is gone, it can only be called by porota.- 
    function setMinister(address _new) external {
        require(msg.sender == _vicepresidente || _poderDeVoto[msg.sender] >= PONGO_A_DEDO);
        require(_new != _vicepresidente);
        minEconomia = _new;

        emit NuevoMinistro(_new, block.timestamp + 30 days);
    }

}