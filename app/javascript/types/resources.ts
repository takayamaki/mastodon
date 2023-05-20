import type { Record } from 'immutable';

import type { components } from '../../../openapi/lib/mastodon';

type NormalizedAccountField = Record<{
  name_emojified: string;
  value_emojified: string;
  value_plain: string;
}>;

interface NormalizedAccountValues {
  display_name_html: string;
  fields: NormalizedAccountField[];
  note_emojified: string;
  note_plain: string;
}

export type Account = Record<
  components['schemas']['account'] & NormalizedAccountValues
>;
