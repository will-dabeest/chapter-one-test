export type WordPartStatus = "mastered" | "needs_work";

export type WordPart = {
  id: number;
  label: string;
  position: number;
  status: WordPartStatus | null;
}
