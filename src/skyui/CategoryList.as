﻿import gfx.events.EventDispatcher;
import gfx.ui.NavigationCode;
import Shared.GlobalFunc;
import skyui.EntryClipManager;
import skyui.CategoryEntryFactory;


class skyui.CategoryList extends skyui.BasicList
{
  /* CONSTANTS */
	
	public static var LEFT_SEGMENT = 0;
	public static var RIGHT_SEGMENT = 1;
	
	
  /* STAGE ELEMENTS */
	
	public var selectorCenter: MovieClip;
	public var selectorLeft: MovieClip;
	public var selectorRight: MovieClip;
	public var background: MovieClip;
	
	
  /* PRIVATE VARIABLES */
	
	private var _xOffset: Number;
	private var _contentWidth: Number;
	private var _totalWidth: Number;
	private var _selectorPos: Number;
	private var _targetSelectorPos: Number;
	private var _bFastSwitch: Boolean;
	private var _segmentOffset: Number;
	private var _segmentLength: Number;


  /* PROPERTIES */
	
	// Distance from border to start icon.
	public var iconIndent: Number;
	
	// Size of the icon.
	public var iconSize: Number;
	
	// Name of movie that contains icons, i.e. skyui_icons_curved.swf.
	public var iconSource: String;
	
	// Array that contains the icon label for category at position i.
	// The category list uses fixed lengths/icons, so this is assigned statically.
	public var iconArt: Array;
	
	// For segmented lists, this is in the index of the divider that seperates player and container/vendor inventory.
	public var dividerIndex: Number;
	
	// The active segment for divided lists (left or right).
	private var _activeSegment: Number;
	
	public function set activeSegment(a_segment: Number)
	{
		if (a_segment == _activeSegment) {
			return;
		}
		
		_activeSegment = a_segment;
		
		calculateSegmentParams();
		
		if (a_segment == LEFT_SEGMENT && _selectedIndex > dividerIndex) {
			doSetSelectedIndex(_selectedIndex - dividerIndex - 1, 0);
		} else if (a_segment == RIGHT_SEGMENT && _selectedIndex < dividerIndex) {
			doSetSelectedIndex(_selectedIndex + dividerIndex + 1, 0);
		}
		
		UpdateList();
	}
	
	public function get activeSegment(): Number
	{
		return _activeSegment;
	}
	
	
  /* CONSTRUCTORS */
	
	public function CategoryList()
	{
		super();
		
		_entryClipManager = new EntryClipManager(new CategoryEntryFactory(this));
		
		_selectorPos = 0;
		_targetSelectorPos = 0;
		_bFastSwitch = false;

		_activeSegment = LEFT_SEGMENT;
		dividerIndex = -1;
		_segmentOffset = 0;
		_segmentLength = 0;
		
		if (iconSize == undefined)
			iconSize = 32;
	}
	
	
  /* PUBLIC FUNCTIONS */
  
  	// Clears the list. For the category list, that's ok since the entryList isn't manipulated directly.
	function clearList()
	{
		dividerIndex = -1;
		_entryList.splice(0);
	}
	
	// Switch to given category index to restore the last selection.
	public function restoreCategory(a_newIndex: Number)
	{
		doSetSelectedIndex(a_newIndex,1);
		onItemPress(1);
	}
	
	// override skyui.DynamicList
	function InvalidateData()
	{
		calculateSegmentParams();
		super.InvalidateData();
	}
	
	// override skyui.DynamicList
	public function UpdateList()
	{
		var cw = 0;

		for (var i = 0; i < _segmentLength; i++) {
			var entryClip = _entryClipManager.getClipByIndex(i);

			setEntry(entryClip,_entryList[i + _segmentOffset]);

			_entryList[i + _segmentOffset].clipIndex = i;
			entryClip.itemIndex = i + _segmentOffset;

			cw = cw + iconSize;
		}

		_contentWidth = cw;
		_totalWidth = background._width;

		var spacing = (_totalWidth - _contentWidth) / (_segmentLength + 1);

		var xPos = anchorEntriesBegin._x + spacing;

		for (var i = 0; i < _segmentLength; i++) {
			var entryClip = _entryClipManager.getClipByIndex(i);
			entryClip._x = xPos;

			xPos = xPos + iconSize + spacing;
			entryClip._visible = true;
		}
		
		updateSelector();
	}
	
	// Moves the selection left to the next element. Wraps around.
	public function moveSelectionLeft()
	{
		if (!_bDisableSelection) {
			var curIndex = _selectedIndex;
			var startIndex = _selectedIndex;
			
			do {
				if (curIndex > _segmentOffset) {
					curIndex--;
				} else {
					_bFastSwitch = true;
					curIndex = _segmentOffset + _segmentLength - 1;
					
				}
			} while (curIndex != startIndex && _entryList[curIndex].filterFlag == 0 && !_entryList[curIndex].bDontHide);
			
			doSetSelectedIndex(curIndex, 0);
			onItemPress(0);
		}
	}

	// Moves the selection right to the next element. Wraps around.
	public function moveSelectionRight()
	{
		if (!_bDisableSelection) {
			var curIndex = _selectedIndex;
			var startIndex = _selectedIndex;
			
			do {
				if (curIndex < _segmentOffset + _segmentLength - 1) {
					curIndex++;
				} else {
					_bFastSwitch = true;
					curIndex = _segmentOffset;
				}
			} while (curIndex != startIndex && _entryList[curIndex].filterFlag == 0 && !_entryList[curIndex].bDontHide);
			
			doSetSelectedIndex(curIndex, 0);
			onItemPress(0);
		}
	}
	
	// GFx
	public function handleInput(details, pathToFocus): Boolean
	{
		var processed = false;

		if (!_bDisableInput) {
			var entry = _entryClipManager.getClipByIndex(selectedIndex);

			processed = entry != undefined && entry.handleInput != undefined && entry.handleInput(details, pathToFocus.slice(1));

			if (!processed && GlobalFunc.IsKeyPressed(details)) {
				if (details.navEquivalent == NavigationCode.LEFT) {
					moveSelectionLeft();
					processed = true;
				} else if (details.navEquivalent == NavigationCode.RIGHT) {
					moveSelectionRight();
					processed = true;
				} else if (!_bDisableSelection && details.navEquivalent == NavigationCode.ENTER) {
					onItemPress(0);
					processed = true;
				}
			}
		}
		return processed;
	}
	
	// override MovieClip
	public function onEnterFrame()
	{
		if (_bFastSwitch && _selectorPos != _targetSelectorPos) {
			_selectorPos = _targetSelectorPos;
			_bFastSwitch = false;
			refreshSelector();
			
		} else  if (_selectorPos < _targetSelectorPos) {
			_selectorPos = _selectorPos + (_targetSelectorPos - _selectorPos) * 0.2 + 1;
			
			refreshSelector();
			
			if (_selectorPos > _targetSelectorPos) {
				_selectorPos = _targetSelectorPos;
			}
			
		} else if (_selectorPos > _targetSelectorPos) {
			_selectorPos = _selectorPos - (_selectorPos - _targetSelectorPos) * 0.2 - 1;
			
			refreshSelector();
			
			if (_selectorPos < _targetSelectorPos) {
				_selectorPos = _targetSelectorPos;
			}
		}
	}
	
	// override skyui.DynamicList
	public function onItemPress(a_keyboardOrMouse: Number)
	{
		if (!_bDisableInput && !_bDisableSelection && _selectedIndex != -1) {
			updateSelector();
			dispatchEvent({type: "itemPress", index: _selectedIndex, entry: _entryList[_selectedIndex], keyboardOrMouse: a_keyboardOrMouse});
		}
	}


  /* PRIVATE FUNCTIONS */
	
	private function calculateSegmentParams()
	{
		// Divided
		if (dividerIndex != undefined && dividerIndex != -1) {
			if (_activeSegment == LEFT_SEGMENT) {
				_segmentOffset = 0;
				_segmentLength = dividerIndex;
			} else {
				_segmentOffset = dividerIndex + 1;
				_segmentLength = _entryList.length - _segmentOffset;
			}
		
		// Default for non-divided lists
		} else {
			_segmentOffset = 0;
			_segmentLength = _entryList.length;
		}
	}
	
	private function updateSelector()
	{
		if (selectorCenter == undefined) {
			return;
		}
			
		if (_selectedIndex == -1) {
			selectorCenter._visible = false;

			if (selectorLeft != undefined) {
				selectorLeft._visible = false;
			}
			if (selectorRight != undefined) {
				selectorRight._visible = false;
			}

			return;
		}

		var selectedClip = _entryClipManager.getClipByIndex(_selectedIndex - _segmentOffset);

		_targetSelectorPos = selectedClip._x + (selectedClip.buttonArea._width - selectorCenter._width) / 2;
		
		selectorCenter._visible = true;
		selectorCenter._y = selectedClip._y + selectedClip.buttonArea._height;
		
		if (selectorLeft != undefined) {
			selectorLeft._visible = true;
			selectorLeft._x = 0;
			selectorLeft._y = selectorCenter._y;
		}

		if (selectorRight != undefined) {
			selectorRight._visible = true;
			selectorRight._y = selectorCenter._y;
			selectorRight._width = _totalWidth - selectorRight._x;
		}
	}

	private function refreshSelector()
	{
		selectorCenter._visible = true;
		var selectedClip = _entryClipManager.getClipByIndex(_selectedIndex - _segmentOffset);

		selectorCenter._x = _selectorPos;

		if (selectorLeft != undefined) {
			selectorLeft._width = selectorCenter._x;
		}

		if (selectorRight != undefined) {
			selectorRight._x = selectorCenter._x + selectorCenter._width;
			selectorRight._width = _totalWidth - selectorRight._x;
		}
	}
	
	// override skyui.DynamicList
	private function setEntry(a_entryClip: MovieClip, a_entryObject: Object)
	{
		if (a_entryClip != undefined) {
			if (a_entryObject.filterFlag == 0 && !a_entryObject.bDontHide) {
				a_entryClip._alpha = 15;
				a_entryClip.enabled = false;
			} else if (a_entryObject == selectedEntry) {
				a_entryClip._alpha = 100;
				a_entryClip.enabled = true;
			} else {
				a_entryClip._alpha = 50;
				a_entryClip.enabled = true;
			}

			setEntryText(a_entryClip,a_entryObject);
		}
	}
}