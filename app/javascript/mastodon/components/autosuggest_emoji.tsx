import React from 'react';
import PropTypes from 'prop-types';
import unicodeMapping from '../features/emoji/emoji_unicode_mapping_light';
import { assetHost } from '../utils/config';

type CustomEmoji = {
  custom: true;
  imageUrl: string;
  native: string;
  colons: `:${string}:`;
}

type NativeEmoji = {
  custom: undefined;
  native: string,
  colons: `:${string}:`,
}

type Emoji = CustomEmoji | NativeEmoji;

type Props = {
  emoji: Emoji;
}
export default class AutosuggestEmoji extends React.PureComponent<Props> {

  static propTypes = {
    emoji: PropTypes.object.isRequired,
  };

  render () {
    const { emoji } = this.props;
    let url;

    if (emoji.custom) {
      url = emoji.imageUrl;
    } else {
      const mapping = unicodeMapping[emoji.native] || unicodeMapping[emoji.native.replace(/\uFE0F$/, '')];

      if (!mapping) {
        return null;
      }

      url = `${assetHost}/emoji/${mapping.filename}.svg`;
    }

    return (
      <div className='autosuggest-emoji'>
        <img
          className='emojione'
          src={url}
          alt={emoji.native || emoji.colons}
        />

        {emoji.colons}
      </div>
    );
  }

}
