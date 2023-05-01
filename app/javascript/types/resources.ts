interface MastodonMap<T> {
  get<K extends keyof T>(key: K): T[K];
  get<K extends keyof T, NSV>(key: K, notSetValue: NSV): T[K] | NSV;
  has<K extends keyof T>(key: K): boolean;
  set<K extends keyof T>(key: K, value: T[K]): this;
}

type AccountField = MastodonMap<{
  name: string;
  value: string;
  verified_at: string | null
}>;

type CustomEmoji = MastodonMap<{
  shortcode: string;
  static_url: string;
  url: string;
  visible_in_picker: boolean;
}>;

type Emoji = CustomEmoji

type RelationShip = MastodonMap<{
  blocked_by: boolean;
  blocking: boolean;
  domain_blocking: boolean;
  endorsed: boolean;
  followed_by: boolean;
  following: boolean;
  id: string;
  languages: string | null;
  muting: boolean;
  muting_notifications: boolean;
  note: string;
  notifying: boolean;
  requested: boolean;
  showing_reblogs: boolean;
}>;

export type Account = MastodonMap<{
  acct: string;
  avatar: string;
  avatar_static: string;
  bot: boolean;
  created_at: string;
  discoverable: boolean;
  display_name: string;
  display_name_html: string;
  emojis: Emoji[];
  fields: AccountField[];
  followers_count: number;
  following_count: number;
  group: boolean;
  header: string;
  header_static: string;
  id: string;
  last_status_at: string;
  locked: boolean;
  moved: boolean;
  mute_expires_at: string | null;
  noindex: boolean;
  note: string;
  relationship?: RelationShip;
  statuses_count: number;
  url: string;
  username: string;
}>;
