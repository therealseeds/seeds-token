pragma solidity ^0.4.16;

contract admined {
  address public admin;

  function admined() {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function transfeAdminship(address newAdmin) onlyAdmin {
    admin = newAdmin;
  }
}

contract Token {
  mapping (address => uint256) public balanceOf;

  string public name;
  string public symbol;
  uint8 public decimal;
  uint256 public totalSupply;

  event Transfer(address indexed from, indexed to, uint256 value);

  function Token(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) {
    balanceOf[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    decimal = decimalUnits;
    symbol = tokenSymbol;
    name = tokenName;
  }

  function transfer(address _to, uint256 _value) {
    require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);

    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    Transfer(msg.sender, _to, _value);
  }
}

contract AssetToken is admined, Token {
  function AssetToken(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits, address centralAdmin) Token(0, tokenName, tokenSymbol, decimalUnits) {
    if (centralAdmin != 0) {
      admin = centralAdmin;
    } else {
      admin = msg.sender;
    }

    balanceOf[admin] = initialSupply;
    totalSupply = initialSupply;
  }

  // For unlimited crowdsale
  function mintToken(address target, uint256 mintedAmount) onlyAdmin {
    balanceOf[target] += mintedAmount;
    totalSupply += mintedAmount;
    Transfer(0, this, mintedAmount);
    Transfer(this, target, mintedAmount);
  }

  // For capped crowdsale
  function tranfer(address _to, uint256 _value) {
    require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);

    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    Transfer(msg.sender, _to, _value);
  }
}
