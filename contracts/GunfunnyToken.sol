// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract TwoPhaseOwnable is Context {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "TwoPhaseOwnable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "TwoPhaseOwnable: new owner is the zero address");
        _pendingOwner = newOwner;
    }

    function acceptOwnership() public virtual {
        require(_msgSender() == pendingOwner(), "TwoPhaseOwnable: sender is not the next choosen one!");
        _setOwner(_pendingOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBPContract {
    function protect(address sender, address receiver, uint256 amount) external;
}

contract GunfunnyToken is ERC20, ERC20Burnable, Pausable, TwoPhaseOwnable {

    IBPContract public bpContract;

    bool public bpEnabled;
    bool public bpDisabledForever;

    constructor() ERC20("Gunfunny Token", "GFY") {
        _mint(msg.sender, 5000000000 * (10 ** uint256(decimals())));  
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function setBPContract(address addr)
        public
        onlyOwner
    {
        require(addr != address(0), "BP adress cannot be 0x0");

        bpContract = IBPContract(addr);
    }

    function setBPEnabled(bool enabled)
        public
        onlyOwner
    {
        bpEnabled = enabled;
    }

    function setBPDisableForever()
        public
        onlyOwner
    {
        require(!bpDisabledForever, "Bot protection disabled");

        bpDisabledForever = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        if (bpEnabled && !bpDisabledForever) {
            bpContract.protect(from, to, amount);
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}
