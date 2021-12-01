pragma solidity ^0.8.2;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract HasForeignAsset is Ownable {
    function assetBalance(IBEP20 asset) external view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function getAsset(IBEP20 asset) external onlyOwner {
        asset.transfer(owner(), this.assetBalance(asset));
    }
}

contract BRANDON is IBEP20, HasForeignAsset {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor() {
        _name = "LET'S GO BRANDON TOKEN";
        _symbol = "$BRANDON";
        _decimals = 6;
        uint256 _maxSupply = 1000000000;
        _mintOnce(msg.sender, _maxSupply);
    }

    receive() external payable {
        revert();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(
            recipient != address(this),
            "BEP20: Transfer to the same contract address"
        );

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mintOnce(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract PrivateSale is Ownable {
    using SafeMath for uint256;

    // The token being sold
    IBEP20 public token;

    // Address where funds are collected
    address payable public wallet;

    struct SaleUser {
        uint256 _lastSaleTimestamp;
        uint256 _countOfSales;
        uint256 _totalAmountOfWeis;
    }

    mapping(address => SaleUser) private saleUsers;

    address payable holder;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    uint256 public _endTime;

    mapping(address => uint256) tokenHolders;
    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    //_rate = 1
    //_wallet = my wallet
    //_token = BRANDON's contract address
    // endTime = 10000000
    //_holder = dev wallet
    constructor(
        uint256 _rate,
        address payable _wallet,
        address _token,
        uint256 endTime,
        address payable _holder
    ) public payable {
        require(_rate > 0);
        require(_wallet != address(0));

        rate = _rate;
        wallet = _wallet;
        token = IBEP20(_token);
        _endTime = endTime;
        holder = _holder;
    }

    fallback() external payable {
        buyTokens(msg.sender);
    }

    receive() external payable {
        buyTokens(msg.sender);
    }

    modifier hasClosed() {
        require(block.timestamp < _endTime, "Presale has already finished");
        _;
    }

    modifier hasTokens() {
        require(token.balanceOf(address(this)) > 0, "No tokens left");
        _;
    }

    modifier isVestingFinished() {
        require(block.timestamp > 1622530800, "Vesting period is over");
        _; //vesting periods ends at 01-06-2021 12:00 pm
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        // uint256 _50Percent = tokens.div(2);
        tokenHolders[_beneficiary] = tokens;
        uint256 fiftyFiveHundredInWei = 1356225716001200128;

        uint256 valueAfterThreePercentTax = (weiAmount / 100) * 3;

        if (saleUsers[_beneficiary]._countOfSales < 1) {
            //DO HERE WHEN FIRST SALe OCCUR
            saleUsers[_beneficiary] = SaleUser(
                block.timestamp,
                saleUsers[_beneficiary]._countOfSales += 1,
                saleUsers[_beneficiary]
                    ._totalAmountOfWeis += valueAfterThreePercentTax
            );
        } else if (
            block.timestamp <
            saleUsers[_beneficiary]._lastSaleTimestamp + 10 minutes &&
            saleUsers[_beneficiary]._totalAmountOfWeis > fiftyFiveHundredInWei
        ) {
            // Do sales tax here more then 5500 per week
            saleUsers[_beneficiary] = SaleUser(
                block.timestamp,
                saleUsers[_beneficiary]._countOfSales += 1,
                saleUsers[_beneficiary]._totalAmountOfWeis += msg.value
            );
        } else if (
            block.timestamp <
            saleUsers[_beneficiary]._lastSaleTimestamp + 10 minutes
        ) {
            //DO SALES TAX MOREE THAN ONE SALE In one Week

            saleUsers[_beneficiary] = SaleUser(
                block.timestamp,
                saleUsers[_beneficiary]._countOfSales += 1,
                saleUsers[_beneficiary]._totalAmountOfWeis += msg.value
            );
        } else {
            // Do sales tax here after one week by week
            saleUsers[_beneficiary] = SaleUser(
                block.timestamp,
                saleUsers[_beneficiary]._countOfSales += 1,
                saleUsers[_beneficiary]._totalAmountOfWeis += msg.value
            );
        }
        // update state
        weiRaised = weiRaised.add(weiAmount);

        _deliverTokens(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        wallet.transfer((msg.value / 100) * 97);
        holder.transfer(valueAfterThreePercentTax);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        view
        hasClosed
        hasTokens
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        return _weiAmount.div(rate);
    }

    // /**
    //  * @dev Determines how ETH is stored/forwarded on purchases.
    //  */
    // function _forwardFunds() internal payable {
    //     uint256 weiAmount = msg.value;
    //     wallet.transfer((weiAmount / 100) * 97);
    // }

    // function _forwardFundsToHolder(uint256 _value) internal payable {
    //     holder.transfer(_value);
    // }

    function withdraw(address withdrawer) public isVestingFinished {
        require(withdrawer != address(0), "BEP20: Transfer to zero address");
        uint256 withdrawnAmount = tokenHolders[withdrawer];
        _deliverTokens(withdrawer, withdrawnAmount);
    }

    function sendTokensBack() public onlyOwner hasClosed {
        token.transferFrom(
            address(this),
            msg.sender,
            token.balanceOf(address(this))
        );
    }
}
