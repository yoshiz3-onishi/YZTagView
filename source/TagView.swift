// ------------------------------------------------------------------------------------------------
import UIKit

// ------------------------------------------------------------------------------------------------
public enum TagViewOptions
{
	case OuterMergine				( CGFloat )
	case InnerMergine				( CGFloat )
	case BackgroundColor			( UIColor )
	case AutoGlowHeight				( Bool )
	case Font						( UIFont )
	case TagBackgroundColor			( UIColor )
	case TagSelectedColor			( UIColor )
	case TagTextColor				( UIColor )
	case TagPrefix					( String )
	case TagMaxCharactors			( Int )
	case AddButtonBackgroundColor	( UIColor )
	case AddButtonTextColor			( UIColor )
	case EnableEdit					( Bool )
	case MaxTagCount				( Int )
}

// ------------------------------------------------------------------------------------------------
@objc public protocol TagViewDelegate
{
	@objc optional func onChangedLayoutTag( sender: UIView )
	@objc optional func onDidEndEditingTag( sender: UIView )
	@objc optional func onTapTag( name: String, userData: Any? )
}

// ------------------------------------------------------------------------------------------------
class TagView: UIView, UITextFieldDelegate
{
	var _scrollView					: UIScrollView!
	var _tagIndex					: Int				  = 0
	var _touchTagIndex				: Int				  = -1
	var _tagFields					: [Int: UITextField]! = [:]
	var _userDatum					: [Int: Any]!		  = [:]
	var _tagFieldMaxX				: CGFloat			  = 0.0
	var _tagFieldMinY				: CGFloat			  = 0.0
	var _basePosition				: CGPoint!
	var _baseSize					: CGSize!
	var _addButton					: UIButton!
	var _outerMergine				: CGFloat			  = 5.0
	var _innerMergine				: CGFloat			  = 2.5
	var _autoGlowHeight				: Bool				  = true
	var _font						: UIFont!
	var _tagBackgroundColor			: UIColor			  = UIColor.white
	var _tagSelectedColor			: UIColor			  = UIColor.white
	var _tagTextColor				: UIColor			  = UIColor.black
	var _tagPrefix					: String			  = "#"
	var _tagMaxCharactors			: Int				  = 30
	var _tagCharCountLabel			: UILabel!
	var _addButtonBackgroundColor	: UIColor			  = UIColor.white
	var _addButtonTextColor			: UIColor			  = UIColor.black
	var _enableEdit					: Bool				  = true
	var _maxTagCount				: Int				  = 1000
	var _tagCount					: Int				  = 0
	var _targetTextField			: UITextField!
	weak var delegate				: TagViewDelegate?

	// --------------------------------------------------------------------------------------------
	required init( coder aDecoder: NSCoder )
	{
		super.init( coder: aDecoder )!
	}
	// --------------------------------------------------------------------------------------------
	override init( frame: CGRect )
	{
		super.init( frame: frame )
	}
	// --------------------------------------------------------------------------------------------
	convenience init( position: CGPoint, size: CGSize, options: [TagViewOptions]? = nil )
	{
		self.init( frame: CGRect( x: position.x, y: position.y, width: size.width, height: size.height ) )

		self.isUserInteractionEnabled = true
		self.addGestureRecognizer( UITapGestureRecognizer( target: self, action: #selector( onTapBackground ) ) )

		_basePosition = position
		_baseSize	  = size

		if let _options = options
		{
			for option in _options
			{
				switch option
				{
					case let .OuterMergine				( value ): _outerMergine			 = value
					case let .InnerMergine				( value ): _innerMergine			 = value
					case let .AutoGlowHeight			( value ): _autoGlowHeight			 = value
					case let .BackgroundColor			( value ): backgroundColor			 = value
					case let .Font						( value ): _font					 = value
					case let .TagBackgroundColor		( value ): _tagBackgroundColor		 = value
					case let .TagSelectedColor			( value ): _tagSelectedColor		 = value
					case let .TagTextColor				( value ): _tagTextColor			 = value
					case let .TagPrefix					( value ): _tagPrefix				 = value
					case let .TagMaxCharactors			( value ): _tagMaxCharactors		 = value
					case let .AddButtonBackgroundColor	( value ): _addButtonBackgroundColor = value
					case let .AddButtonTextColor		( value ): _addButtonTextColor		 = value
					case let .EnableEdit				( value ): enableEdit				 = value
					case let .MaxTagCount				( value ): _maxTagCount				 = value
				}
			}
		}

		_scrollView								= UIScrollView( frame: frame )
		_scrollView.isPagingEnabled				= false
		_scrollView.frame						= CGRect( x: 0, y: 0, width: frame.width, height: frame.height )
		_scrollView.contentSize					= CGSize( width: frame.width, height: frame.height )
		_scrollView.layer.position				= CGPoint( x: frame.width / 2, y: frame.height / 2 )
		_scrollView.showsVerticalScrollIndicator = false
		_scrollView.isUserInteractionEnabled	= true
		self.addSubview( _scrollView )

		_addButton								= UIButton( frame: CGRect( x: 0, y: 0, width: 30, height: 30 ) )
		_addButton.layer.anchorPoint			= CGPoint( x: 0.0, y: 0.5 )
		_addButton.layer.position				= CGPoint( x: _outerMergine, y: _outerMergine + _addButton.frame.height / 2 )
		_addButton.isHidden						= !_enableEdit
		_addButton.titleLabel?.font				= _font
		_addButton.layer.masksToBounds			= true
		_addButton.isUserInteractionEnabled		= true
		_addButton.layer.cornerRadius			= _addButton.frame.height / 2
		_addButton.layer.borderColor			= _addButtonTextColor.cgColor
		_addButton.layer.borderWidth			= 1.5
		_addButton.backgroundColor				= _addButtonBackgroundColor
		_addButton.setTitle( "+", for: UIControlState.normal )
		_addButton.setTitleColor( _addButtonTextColor, for: UIControlState.normal )
		_addButton.setTitle( "+", for: UIControlState.highlighted )
		_addButton.setTitleColor( _addButtonTextColor, for: UIControlState.highlighted )
		_addButton.setBackgroundImage( UIImage.createImageFromColor( color: UIColor.white ), for: .highlighted )
		_addButton.addTarget( self, action: #selector( onTapAddButton ), for: .touchUpInside )
		self.addSubview( _addButton )

		_tagCharCountLabel						= UILabel( frame: CGRect( x: 0, y: 0, width: 51, height: 20 ) )
		_tagCharCountLabel.layer.anchorPoint	= CGPoint( x: 1.0, y: 0.5 )
		_tagCharCountLabel.font					= Utility.getSystemFont( size: 10 )
		_tagCharCountLabel.textColor			= _addButtonTextColor
		_tagCharCountLabel.textAlignment		= NSTextAlignment.center
		_tagCharCountLabel.layer.zPosition		= 5000
		_tagCharCountLabel.backgroundColor		= UIColor.white
		_tagCharCountLabel.layer.masksToBounds	= true
		_tagCharCountLabel.layer.cornerRadius	= 20 / 2
		_tagCharCountLabel.layer.borderColor	= _addButtonTextColor.cgColor
		_tagCharCountLabel.layer.borderWidth	= 1.5
		_tagCharCountLabel.isHidden				= true
		self.addSubview( _tagCharCountLabel )
	}

	// --------------------------------------------------------------------------------------------
	var enableEdit: Bool
	{
		get
		{
			return _enableEdit
		}
		set( newFlag )
		{
			if _addButton != nil
			{
				_addButton.isHidden = !newFlag
			}
			for index in 0 ..< _tagFields.count
			{
				_tagFields[ index ]?.isEnabled = newFlag
			}
			_enableEdit = newFlag
		}
	}
	// --------------------------------------------------------------------------------------------
	func getTags( withPrefix: Bool ) -> [String]
	{
		var tags: [String] = []
		for ( _, value ) in _tagFields.sorted( by: { $0.0 < $1.0 } )
		{
			if withPrefix == true
			{
				if value.text!.range( of: _tagPrefix ) != nil
				{
					tags.append( value.text! )
				}
				else
				{
					tags.append( _tagPrefix + value.text! )
				}
			}
			else
			{
				if value.text!.range( of: _tagPrefix ) != nil
				{
					tags.append( value.text!.replacingOccurrences( of: _tagPrefix, with: "" ) )
				}
				else
				{
					tags.append( value.text! )
				}
			}
		}
		return tags
	}

	// --------------------------------------------------------------------------------------------
	// layout functions
	// --------------------------------------------------------------------------------------------
	func addTag( tagString: String, userData: Any? = nil )
	{
		let tagField				= UITextField( frame: CGRect( x: 0, y: 0, width: 60, height: 30 ) )
		tagField.layer.anchorPoint	= CGPoint( x: 0.0, y: 0.0 )
		tagField.layer.position		= CGPoint( x: _outerMergine + _tagFieldMaxX, y: _outerMergine + _tagFieldMinY )
		tagField.backgroundColor	= _tagBackgroundColor
		tagField.textColor			= _tagTextColor
		tagField.text				= tagString
		tagField.tintColor			= _addButtonTextColor
		tagField.font				= _font
		tagField.textAlignment		= NSTextAlignment.center
		tagField.delegate			= self
		tagField.borderStyle		= UITextBorderStyle.roundedRect
		tagField.returnKeyType		= UIReturnKeyType.done
		tagField.tag				= _tagIndex
		tagField.isEnabled			= _enableEdit
		tagField.becomeFirstResponder()
		tagField.sizeToFit()
		_scrollView.addSubview( tagField )
		_tagFields[ _tagIndex ] = tagField
		_userDatum[ _tagIndex ] = userData
		fitTag( tagField: tagField )
		updateLayout()
		_tagIndex += 1
		hideCharactorCount()
	}
	// --------------------------------------------------------------------------------------------
	func removeTag( tagField: UITextField )
	{
		_tagFields.removeValue( forKey: tagField.tag )
		_userDatum.removeValue( forKey: tagField.tag )
		tagField.removeFromSuperview()
	}
	// --------------------------------------------------------------------------------------------
	func fitTag( tagField: UITextField )
	{
		if 0 < tagField.text!.characters.count
		{
			if ( tagField.text! as NSString ).substring( to: _tagPrefix.characters.count ) != _tagPrefix
			{
				tagField.text = _tagPrefix + tagField.text!
			}
		}
		tagField.sizeToFit()
		tagField.frame = CGRect( x: tagField.layer.position.x, y: tagField.layer.position.y, width: tagField.frame.width + _innerMergine * 2, height: tagField.frame.height + _innerMergine * 2 )
	}
	// --------------------------------------------------------------------------------------------
	func updateLayout()
	{
		_tagFieldMaxX = 0.0
		_tagFieldMinY = _outerMergine
		var tagFieldMaxY = CGFloat( 0.0 )
		for ( _, value ) in _tagFields.sorted( by: { $0.0 < $1.0 } )
		{
			value.frame = CGRect( x: _tagFieldMaxX + _outerMergine, y: _tagFieldMinY, width: value.frame.width, height: value.frame.height )
			if frame.width - _outerMergine * 2 < value.frame.width
			{
				value.frame = CGRect( x: _outerMergine, y: value.frame.maxY + _outerMergine, width: frame.width - _outerMergine * 2, height: value.frame.height )
			}
			else if frame.width - _outerMergine < value.frame.maxX
			{
				value.layer.position = CGPoint( x: _outerMergine, y: value.frame.maxY + _outerMergine )
			}
			_tagFieldMaxX = value.frame.maxX
			_tagFieldMinY = value.frame.minY
			if tagFieldMaxY < value.frame.maxY
			{
				tagFieldMaxY = value.frame.maxY
			}
		}
		if _tagFields.count == 0
		{
			_addButton.layer.position = CGPoint( x: _outerMergine, y: _outerMergine + _addButton.frame.height / 2 )
		}
		else
		{
			_addButton.layer.position = CGPoint( x: _tagFieldMaxX + _outerMergine, y: _tagFieldMinY + ( tagFieldMaxY - _tagFieldMinY ) / 2 )
		}
		if frame.width - _outerMergine < _addButton.frame.maxX
		{
			_addButton.layer.position = CGPoint( x: _outerMergine, y: tagFieldMaxY + _outerMergine + _addButton.frame.height / 2 )
			if tagFieldMaxY < _addButton.frame.maxY
			{
				tagFieldMaxY = _addButton.frame.maxY
			}
		}
		_scrollView.contentSize = CGSize( width: frame.width, height: tagFieldMaxY + _outerMergine )
		if _autoGlowHeight == true
		{
			frame = CGRect( x: _basePosition.x, y: _basePosition.y, width: _baseSize.width, height: max( _baseSize.height, _scrollView.contentSize.height ) )
			_scrollView.frame = CGRect( x: 0, y: 0, width: frame.width, height: frame.height )
			delegate?.onChangedLayoutTag!( sender: self )
		}
	}
	// --------------------------------------------------------------------------------------------
	func updateCharactorCount()
	{
		_tagCharCountLabel.isHidden		  = false
		_tagCharCountLabel.text			  = _targetTextField.text!.characters.count.description + " / " + _tagMaxCharactors.description
		_tagCharCountLabel.layer.position = CGPoint( x: _targetTextField.frame.maxX, y: _targetTextField.frame.maxY + 5 )
		_tagCharCountLabel.text			  = _targetTextField.text!.characters.count.description + " / " + _tagMaxCharactors.description
	}
	// --------------------------------------------------------------------------------------------
	func hideCharactorCount()
	{
		_tagCharCountLabel.isHidden = true
	}

	// --------------------------------------------------------------------------------------------
	// event functions
	// --------------------------------------------------------------------------------------------
	func onTapAddButton( sender: UIButton )
	{
		if 0 < _maxTagCount - _tagCount
		{
			addTag( tagString: _tagPrefix )
			_tagCount += 1
			_addButton.isHidden = ( _maxTagCount - _tagCount ) == 0
		}
	}
	// --------------------------------------------------------------------------------------------
	func textFieldShouldBeginEditing( _ textField: UITextField ) -> Bool
	{
		_targetTextField = textField
		updateCharactorCount()
		return true
	}
	// --------------------------------------------------------------------------------------------
	func textField( _ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String ) -> Bool
	{
		Timer.scheduledTimer( timeInterval: 0.05, target: self, selector: #selector( onTimerTextField ), userInfo: _tagFields[ textField.tag ]!, repeats: false )
		return true
	}
	// --------------------------------------------------------------------------------------------
	func onTimerTextField( timer: Timer )
	{
		if _tagMaxCharactors < _targetTextField.text!.characters.count
		{
			_targetTextField.text = ( _targetTextField.text! as NSString ).substring( to: _tagMaxCharactors )
		}
		updateCharactorCount()
		fitTag( tagField: timer.userInfo as! UITextField )
		updateLayout()
	}
	// --------------------------------------------------------------------------------------------
	func textFieldDidEndEditing( _ textField: UITextField )
	{
		if textField.text == "" || textField.text == _tagPrefix
		{
			removeTag( tagField: _tagFields[ textField.tag ]! )
			_tagCount -= 1
			_addButton.isHidden = ( _maxTagCount - _tagCount ) == 0
		}
		else
		{
			fitTag( tagField: _tagFields[ textField.tag ]! )
		}
		updateLayout()
	}
	// --------------------------------------------------------------------------------------------
	func textFieldShouldReturn( _ textField: UITextField ) -> Bool
	{
		textField.resignFirstResponder()
		hideCharactorCount()
		endEditing( true )
		delegate?.onDidEndEditingTag!( sender: self )
		return true
	}
	// --------------------------------------------------------------------------------------------
	func onTapBackground( sender: UITapGestureRecognizer )
	{
		let point = sender.location( in: self )
		for index in 0 ..< _tagFields.count
		{
			if _tagFields[ index ]?.frame.contains( point ) == true
			{
				_tagFields[ index ]!.backgroundColor = _tagSelectedColor
				Timer.scheduledTimer( timeInterval: 0.05, target: self, selector: #selector( self.onTouchEnd ), userInfo: index, repeats: false )
				_touchTagIndex = index
				return
			}
		}
	}
	// --------------------------------------------------------------------------------------------
	func onTouchEnd( timer: Timer )
	{
		_tagFields[ _touchTagIndex ]!.backgroundColor = _tagBackgroundColor
		delegate?.onTapTag!( name: ( _tagFields[ _touchTagIndex ]?.text )!, userData: _userDatum[ _touchTagIndex ] )
	}
}
